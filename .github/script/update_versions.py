import os
import json
from github import Github

def update_latest_versions():
    version = os.environ["GITHUB_REF"].split("/")[-1]
    
    # Preview sürümlerini kontrol et ve sadece preview sürümleri için güncelleme yap
    if "preview" not in version:
        return False
    
    with open("latest-versions.json", "r") as f:
        latest_versions = json.load(f)

    latest_versions["version"] = version

    with open("latest-versions.json", "w") as f:
        json.dump(latest_versions, f, indent=2)
    
    return True


def create_pr():
    g = Github(os.environ["GITHUB_TOKEN"])
    repo = g.get_repo("skoc10/my_project")

    branch_name = f"update-latest-versions-{os.environ['GITHUB_REF'].split('/')[-1]}"
    base = repo.get_branch("main")
    repo.create_git_ref(ref=f"refs/heads/{branch_name}", sha=base.commit.sha)

    repo.update_file("latest-versions.json", "Update latest-versions.json", open("latest-versions.json", "r").read(),
                     base.commit.commit.tree.sha, branch=branch_name)

    pr = repo.create_pull(title="Update latest-versions.json",
                          body="Automated PR to update the latest-versions.json file.",
                          head=branch_name, base="main")

    pr.create_review_request(reviewers=["skoc10"])

if __name__ == "__main__":
    should_create_pr = update_latest_versions()
    if should_create_pr:
        create_pr()

