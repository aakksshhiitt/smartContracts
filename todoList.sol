// this is a basic smart contract for to do list that let the user to save their tasks, check for the task details using the task number and mark the task as completed.

// SPDX-License-Identifier:MIT
pragma solidity^0.8.28;

contract todo{

    struct Task{
        uint256 id;
        string description;
        bool completed;
    }

    string[] tasks;
    mapping(address=>mapping(uint256=>Task)) taskList;
    mapping(address=>uint256) currentTask;

    event TaskAdded(address indexed user, uint256 indexed taskNumber, string indexed value);

//function to add new task in the list
    function addTask(string memory _task) public{
        Task memory t=Task(currentTask[msg.sender],_task,false);
        taskList[msg.sender][currentTask[msg.sender]++]=t;
        emit TaskAdded(msg.sender,currentTask[msg.sender]-1, _task);
    }

//function to show the task for particular task number
    function showMyTask(uint256 _taskNumber) public view returns(Task memory){
        require(_taskNumber<currentTask[msg.sender],"There is no task for this number");
        return taskList[msg.sender][_taskNumber];
    } 

//show total task added in the list
    function totalTaskCount() public view returns(uint){
        if(currentTask[msg.sender]==0)
        return 0;
        return currentTask[msg.sender];
    }

//function to mark a task as completed
    function markTaskAsCompleted(uint256 _taskNumber) public{
        require(taskList[msg.sender][_taskNumber].completed==false,"Sorry this task is already completed");
        require(_taskNumber<currentTask[msg.sender],"There is no task for this number");
        taskList[msg.sender][_taskNumber].completed=true;
    }

//function to show the task status, true as completed and flase as not completed.
    function showTaskStatus(uint256 _taskNumber) public view returns(bool){
        require(_taskNumber<currentTask[msg.sender],"There is no task for this number");
        return taskList[msg.sender][_taskNumber].completed;
    }
}