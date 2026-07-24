"""Script to create and update Data Analytics Agents.

This script automates the creation of a Gemini Data Analytics Agent and updates its
configuration based on a YAML template. It handles configuration merging,
environment variable substitution, and polling for operation completion.
"""

import os
import sys
import time
import json
import yaml
from google.cloud import geminidataanalytics_v1beta as geminidataanalytics
from google.protobuf import field_mask_pb2

# Resolve paths relative to this script's directory
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_YAML_FILE = os.path.join(SCRIPT_DIR, "agent.yaml")
CONFIG_OUTPUT_DIR = os.path.join(SCRIPT_DIR, "config")
DEFAULT_OUTPUT_CONFIG = os.path.join(CONFIG_OUTPUT_DIR, "agent.yaml")

def get_client():
    """Initializes and returns the DataAgentServiceClient."""
    return geminidataanalytics.DataAgentServiceClient()

def create_agent(project_id, location="global", yaml_file=DEFAULT_YAML_FILE):
    """Creates a basic Data Agent if it does not already exist.

    Args:
        project_id: The GCP project ID.
        location: The GCP location (default 'global').
        yaml_file: The path to the template YAML file to read default display name and description.
    """
    client = get_client()
    parent = f"projects/{project_id}/locations/{location}"
    
    display_name = "DSG Financial Agent"
    description = "DSG Financial Agent (evaluates sales performance, revenue, store metrics, and inventory value)"
    
    if os.path.exists(yaml_file):
        with open(yaml_file, 'r') as f:
            config = yaml.safe_load(f)
            display_name = config.get('display_name', display_name)
            description = config.get('description', description)
    else:
        print(f"YAML file {yaml_file} not found. Using defaults for initial creation.")
        
    # Check if agent already exists
    try:
        page_result = client.list_data_agents(parent=parent)
        for existing_agent in page_result:
            if existing_agent.display_name == display_name:
                print(f"Agent with display name '{display_name}' already exists: {existing_agent.name}")
                # Save the config so update_config can find it
                save_agent_config(existing_agent)
                return
    except Exception as e:
         print(f"Error checking for existing agent: {e}")
         sys.exit(1)

    agent = geminidataanalytics.DataAgent(
        display_name=display_name,
        description=description
    )
    
    request = geminidataanalytics.CreateDataAgentRequest(
        parent=parent,
        data_agent=agent
    )
    
    print(f"Creating agent in {parent}...")
    try:
        operation = client.create_data_agent(request=request)
        response = operation.result() # Blocks until operation completes
        print(f"Agent created successfully: {response.name}")
        save_agent_config(response)
            
    except Exception as e:
        print(f"Error creating agent: {e}")
        sys.exit(1)

def save_agent_config(agent):
    """Saves the agent configuration to a local YAML file for later use.

    Args:
        agent: The DataAgent object to save.
    """
    config_dict = geminidataanalytics.DataAgent.to_dict(agent)
    os.makedirs(CONFIG_OUTPUT_DIR, exist_ok=True)
    
    with open(DEFAULT_OUTPUT_CONFIG, "w") as f:
        yaml.dump(config_dict, f, sort_keys=False, indent=2)
    print(f"Saved current agent state to {DEFAULT_OUTPUT_CONFIG}")

def update_config(agent_yaml_path=DEFAULT_OUTPUT_CONFIG, template_yaml_path=DEFAULT_YAML_FILE):
    """Updates the agent configuration by merging a template with the current state.

    Args:
        agent_yaml_path: Path to the current agent config file.
        template_yaml_path: Path to the template YAML file with overrides.
    """
    client = get_client()
    
    if not os.path.exists(agent_yaml_path):
        print(f"Current agent config file {agent_yaml_path} not found. Run create_agent first.")
        sys.exit(1)
        
    with open(agent_yaml_path, 'r') as f:
        agent_dict = yaml.safe_load(f)

    if not os.path.exists(template_yaml_path):
        print(f"Template file {template_yaml_path} not found.")
        sys.exit(1)

    project_id = os.environ.get('PROJECT_ID')
    if not project_id:
        print("ERROR: PROJECT_ID environment variable is required for configuration update.")
        sys.exit(1)
    
    with open(template_yaml_path, 'r') as f:
        yaml_content = f.read()
        
    # Substitute environment variables in the template
    yaml_content = yaml_content.replace('__PROJECT_ID__', project_id)
    override_dict = yaml.safe_load(yaml_content)
        
    # Perform targeted merge for nested structures to avoid overwriting entire objects
    merge_configurations(agent_dict, override_dict)
        
    agent_name = agent_dict.get('name')
    if not agent_name:
        print("Agent 'name' missing from configuration.")
        sys.exit(1)

    print(f"Updating agent: {agent_name}")

    # Remove read-only fields that API rejects on update
    if 'data_analytics_agent' in agent_dict:
        daa = agent_dict['data_analytics_agent']
        if 'last_published_context' in daa:
            print("Pruning read-only field: last_published_context")
            del daa['last_published_context']

    # Convert dict back to Proto via JSON to ensure correct types
    agent_proto = geminidataanalytics.DataAgent.from_json(json.dumps(agent_dict))
    
    paths = [
        "display_name",
        "description",
        "labels",
        "data_analytics_agent.published_context"
    ]
    
    update_mask = field_mask_pb2.FieldMask(paths=paths)
    
    request = geminidataanalytics.UpdateDataAgentRequest(
        data_agent=agent_proto,
        update_mask=update_mask,
    )

    try:
        operation = client.update_data_agent(request=request)
        print("Update operation in progress...")
        
        # Use operation.result() which blocks and handles polling internally
        response = operation.result()
        print(f"Update completed successfully for {response.name}")
        
    except Exception as e:
        print(f"Error updating agent: {e}")
        sys.exit(1)

def merge_configurations(current_dict, override_dict):
    """Helper to perform targeted merge of specific nested configurations.

    Modifies current_dict in-place.
    """
    if 'data_analytics_agent' in override_dict and 'data_analytics_agent' in current_dict:
        oa = override_dict['data_analytics_agent']
        aa = current_dict['data_analytics_agent']
        if 'published_context' in oa and 'published_context' in aa:
            opc = oa['published_context']
            apc = aa['published_context']
            
            # Specifically override these lists/sub-objects rather than the whole context
            if 'datasource_references' in opc:
                apc['datasource_references'] = opc['datasource_references']
            if 'system_instruction' in opc:
                apc['system_instruction'] = opc['system_instruction']
            if 'example_queries' in opc:
                apc['example_queries'] = opc['example_queries']

    # Shallow merge for any top-level fields not already handled
    for key, value in override_dict.items():
        if key not in current_dict:
            current_dict[key] = value

if __name__ == "__main__":
    project_id = os.environ.get('PROJECT_ID')
    if not project_id:
        print("ERROR: PROJECT_ID environment variable is required.")
        sys.exit(1)
        
    create_agent(project_id)
    update_config()
