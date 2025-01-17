import subprocess
import csv
from dateutil import parser
import argparse
import os


def get_commit_counts(repo_path: str, author: str = None) -> dict:
    """
    Extract commit counts by date from a git repository across all branches.
    """
    original_dir = os.getcwd()
    os.chdir(repo_path)

    try:
        git_log_command = [
            'git', 'log',
            '--format=%aI',
            '--no-merges',
            '--all',
        ]
        if author:
            git_log_command.extend(['--author', author])

        result = subprocess.run(
            git_log_command, capture_output=True, text=True, check=True
        )

        contribution_data = {}
        for line in filter(None, result.stdout.strip().split('\n')):
            date = parser.parse(line).strftime('%Y-%m-%d')
            contribution_data[date] = contribution_data.get(date, 0) + 1

        return contribution_data

    finally:
        os.chdir(original_dir)


def save_contribution_data_csv(contribution_data: dict, output_file: str):
    """
    Save contribution data as a CSV file.
    """
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['date', 'commits'])
        for date, count in sorted(contribution_data.items()):
            writer.writerow([date, count])


def main():
    parser = argparse.ArgumentParser(description="Extract git repository contribution data")
    parser.add_argument('repo_path', help="Path to git repository")
    parser.add_argument(
        '--output', '-o', default='contribution_data.csv', help="Output CSV file (default: contribution_data.csv)"
    )
    parser.add_argument('--author', help="Filter commits by author (email or name)")

    args = parser.parse_args()

    if not os.path.exists(os.path.join(args.repo_path, '.git')):
        print(f"Error: {args.repo_path} is not a git repository")
        return 1

    try:
        contribution_data = get_commit_counts(args.repo_path, args.author)
        save_contribution_data_csv(contribution_data, args.output)

        print(f"Contributions saved to {args.output}")
        print(f"Found commits on {len(contribution_data)} unique days.")

        print("\nSample data:")
        for date, count in sorted(contribution_data.items(), reverse=True)[:5]:
            print(f"{date}: {count} commits")

    except subprocess.CalledProcessError as e:
        print(f"Error executing git command: {e}")
        return 1
    except Exception as e:
        print(f"Error: {e}")
        return 1

    return 0


if __name__ == '__main__':
    exit(main())
