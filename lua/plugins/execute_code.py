import argparse
from databricks.sdk import WorkspaceClient
from databricks.sdk.service import compute
from databricks.sdk.service.compute import CommandStatus
import time
import os
from datetime import datetime, timedelta


def context_is_running(profile: str, cluster_id: str, context_id: str) -> bool:
    """
    Check if a context is running.

    Parameters:
        profile: str
        cluster_id: str
        context_id: str

    Returns:
        bool
    """
    client = WorkspaceClient(profile=profile)
    try:
        res = client.command_execution.context_status(cluster_id, context_id)
        print(res.as_dict())
        return res.status.value == "Running"
    except Exception:
        return False


def get_execution_context(profile: str, cluster_id: str) -> str:
    """
    Get a new or old execution context. It starts to reading looking for a file at __file__/.execution_context . If one is
    found it will check it is still running. Else it will create a new one.

    Parameters:
        profile: str
        cluster_id: str

    Returns:
        bool

    """
    path = os.path.join(os.path.dirname(__file__), ".execution_context")
    if os.path.exists(path):
        print(path)
        with open(path, "r") as f:
            file = f.readlines()
            id, last_time = file[-1].split(",")
        if context_is_running(profile, cluster_id, id):
            print(f"execution context is running with conext_id: {id}")
            return id

    print("Execution context is not running. Creating a new context...")
    cur_time = datetime.now()
    client = WorkspaceClient(profile=profile)
    new_context = client.command_execution.create(
        cluster_id=cluster_id,
        language=compute.Language.PYTHON,
    ).result()
    with open(path, "w") as f:
        f.write(f"{new_context.id},{cur_time}")
    print(f"new context_id: {new_context.id}")
    return new_context.id


def execute_code(cmd: str, profile: str, cluster_id: str) -> dict:
    """
    Send python code to execute on databricks. It currenly creates a new execution
    context for each run.

    Parameters:
        cmd (str): Python code to execute
        profile: Databricks profile set up in ~/.databrickscfg
        cluster_id: the cluster id for code to be executed on

    Returns:
        str: command output
    """
    client = WorkspaceClient(profile=profile)
    for query in client.queries.list():
        print(query.as_dict())
    context_id = get_execution_context(profile, cluster_id)

    # Check the status of the command execution
    while True:
        response = client.command_execution.execute(
            cluster_id=cluster_id,
            context_id=context_id,
            language=compute.Language.PYTHON,
            command=cmd,
        ).result()

        print(response.status)
        if response.status in [
            CommandStatus.FINISHED,
            CommandStatus.CANCELLED,
            CommandStatus.ERROR,
        ]:
            break

        print(f"Command status: {response.status}")
        time.sleep(5)  # Wait for 5 seconds before checking again

    if response.status == CommandStatus.ERROR:
        return {
            "status": response.status,
            "cause": response.results.cause,
        }
    else:
        return {
            "status": response.status,
            "data": response.results.data,
        }


def main() -> None:
    """
    When script is ran read in args and execute code
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--code")
    parser.add_argument("--profile")
    parser.add_argument("--cluster_id")
    args = parser.parse_args()

    print(execute_code(args.code, args.profile, args.cluster_id))


if __name__ == "__main__":
    main()
