import sys
import os

def parse_recutils(content):
    """Parse recutils content into a list of records and maintain field order."""
    records = []
    current_record = {}
    field_order = []  # To store the order of fields
    
    for line in content.split('\n'):
        # Skip empty lines and comments
        if not line.strip() or line.startswith('%'):
            continue
            
        if ': ' in line:
            key, value = line.split(': ', 1)
            current_record[key] = value
            # Add field to order list if it's not already there
            if key not in field_order:
                field_order.append(key)
        else:
            # If we hit a line without a colon and have a record, save it
            if current_record:
                records.append(current_record)
                current_record = {}
    
    # Don't forget to add the last record
    if current_record:
        records.append(current_record)
    
    return records, field_order

def create_markdown_table(records, field_order):
    """Convert records into a markdown table string using specified field order."""
    if not records:
        return ""
    
    # Create the header row using the original field order
    table = "| " + " | ".join(field_order) + " |\n"
    
    # Create the separator row
    table += "| " + " | ".join(["---"] * len(field_order)) + " |\n"
    
    # Create data rows
    for record in records:
        row = []
        for field in field_order:
            # Get value or empty string if key doesn't exist
            value = record.get(field, "")
            row.append(value)
        table += "| " + " | ".join(row) + " |\n"
    
    return table

def convert_file(input_filepath):
    """Convert a recutils file to a markdown file."""
    # Read the input file
    try:
        with open(input_filepath, 'r') as file:
            content = file.read()
    except FileNotFoundError:
        print(f"Error: Could not find file '{input_filepath}'")
        return
    except Exception as e:
        print(f"Error reading file: {e}")
        return

    # Generate the output filename
    base_name = os.path.splitext(input_filepath)[0]
    output_filepath = f"{base_name}.md"

    # Parse and convert the content
    records, field_order = parse_recutils(content)
    markdown_table = create_markdown_table(records, field_order)

    # Write the markdown file
    try:
        with open(output_filepath, 'w') as file:
            file.write(markdown_table)
        print(f"Successfully created '{output_filepath}'")
    except Exception as e:
        print(f"Error writing markdown file: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <input_file.rec>")
        sys.exit(1)
    
    convert_file(sys.argv[1])
