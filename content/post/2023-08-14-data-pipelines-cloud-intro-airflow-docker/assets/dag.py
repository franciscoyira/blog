from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

with DAG(
    "tutorial",
    description="A simple tutorial DAG",
    schedule_interval=timedelta(days=1),
    start_date=datetime(2021, 1, 1),
    catchup=False,
    tags=["example_tag"],
) as dag:
    
    # Task 1
    t1 = BashOperator(
        task_id="print_date",
        bash_command="date",
    )

    # Task 2
    t2 = BashOperator(
        task_id="sleep",
        bash_command="sleep 5",
        retries=3,
    )

    # Task 3
    t3 = BashOperator(
        task_id="echo_execution_date",
        bash_command="echo {{ ds }}",
    )

    t1 >> [t2, t3]
