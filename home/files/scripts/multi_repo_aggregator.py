import subprocess
import csv
import argparse
import os
from typing import Dict, List


def load_contribution_data_csv(csv_file: str) -> Dict[str, int]:
    """
    Load contribution data from a CSV file.
    """
    if not os.path.exists(csv_file):
        return {}
    with open(csv_file, 'r') as f:
        reader = csv.reader(f)
        next(reader)  # Skip the header
        return {row[0]: int(row[1]) for row in reader}


def aggregate_contributions(
    repo_paths: List[str], existing_data: Dict[str, int], author: str = None
) -> Dict[str, int]:
    """
    Aggregate contribution data from multiple repositories and merge with existing data.
    """
    aggregated_data = existing_data.copy()
    temp_dir = 'temp_contributions'
    os.makedirs(temp_dir, exist_ok=True)

    try:
        for i, repo_path in enumerate(repo_paths):
            temp_file = os.path.join(temp_dir, f'repo_{i}.csv')
            cmd = ['python3', 'git_contribution_extractor.py', repo_path, '--output', temp_file]
            if author:
                cmd.extend(['--author', author])

            print(f"Processing repository: {repo_path}")
            subprocess.run(cmd, check=True)

            repo_data = load_contribution_data_csv(temp_file)
            for date, count in repo_data.items():
                aggregated_data[date] = aggregated_data.get(date, 0) + count

    finally:
        # Clean up temporary files
        for file in os.listdir(temp_dir):
            os.remove(os.path.join(temp_dir, file))
        os.rmdir(temp_dir)

    return aggregated_data


def save_aggregated_data_csv(data: Dict[str, int], output_file: str):
    """
    Save aggregated contribution data as a CSV file.
    """
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['date', 'commits'])
        for date, count in sorted(data.items()):
            writer.writerow([date, count])


def main():
    parser = argparse.ArgumentParser(description="Aggregate git contributions from multiple repositories")
    parser.add_argument(
        'repo_paths', nargs='+', help="Paths to git repositories (space-separated)"
    )
    parser.add_argument(
        '--output', '-o',
        default='aggregated_contributions.csv',
        help="Output CSV file (default: aggregated_contributions.csv)",
    )
    parser.add_argument(
        '--author',
        help="Filter commits by author (email or name)",
    )
    parser.add_argument(
        '--merge',
        action='store_true',
        help="Merge with existing data in output file",
    )

    args = parser.parse_args()

    invalid_repos = [path for path in args.repo_paths if not os.path.exists(os.path.join(path, '.git'))]
    if invalid_repos:
        print(f"Error: The following are not valid git repositories: {', '.join(invalid_repos)}")
        

    existing_data = load_contribution_data_csv(args.output) if args.merge and os.path.exists(args.output) else {}

    try:
        aggregated_data = aggregate_contributions(args.repo_paths, existing_data, args.author)
        save_aggregated_data_csv(aggregated_data, args.output)

        print(f"Aggregated contributions saved to {args.output}")
        print(f"Commits found on {len(aggregated_data)} unique days across {len(args.repo_paths)} repositories.")

        if args.merge:
            print(f"Added data for {len(aggregated_data) - len(existing_data)} new days.")

        # Display sample data
        print("\nSample of the aggregated data:")
        for date, count in sorted(aggregated_data.items(), reverse=True)[:5]:
            print(f"{date}: {count} commits")

    except subprocess.CalledProcessError as e:
        print(f"Error processing repositories: {e}")
        return 1
    except Exception as e:
        print(f"Error: {e}")
        return 1

    return 0


if __name__ == '__main__':
    exit(main())
