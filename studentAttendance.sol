// SPDX-Licese-Identifier:MIT
pragma solidity ^0.8.28;

contract studentAttendance{

    address manager;
    struct Student{
        uint256 studentId;
        string studentName;
        uint8 age;
        uint8 standard;
        uint256 attendanceCount;
    }
    mapping(uint256=>Student) studentList;
    uint256 [] allStudents;

    constructor(){
        manager=msg.sender;
    }

// event declaration
    event studentRegistered(uint256 indexed studentId, string indexed studentName, uint8 indexed standard);
    event attendanceMarked(uint256 studentId, uint256 time);
    event studentRemoved(uint256 studentId);

// function to register new student
    function registerStudent(uint256 _studentId, string memory _studentName, uint8 _age, uint8 _standard) public{
        require(msg.sender==manager,"Only manager can add new student to the list");
        require(_age>0, "Please provide a valid age");
        require(studentList[_studentId].age==0,"Sorry this student id already exist, please check");

        uint8 flag=0;
        Student memory s=Student(_studentId, _studentName, _age, _standard, 0);
        studentList[_studentId]=s;
        for(uint i=0;i<allStudents.length;i++){
            if(allStudents[i]==0){
                allStudents[i]=_studentId;
                flag=1;
                break;
            }
        }
        if(flag==0)
        allStudents.push(_studentId);

        emit studentRegistered(_studentId, _studentName, _standard);
    }

// function to get the details for a particular student using the student id.
    function viewStudentDetails(uint256 _studentId) public view returns(Student memory){
        require(studentList[_studentId].age!=0,"Sorry this student id is not registered");
        return studentList[_studentId];
    }

// getter function for checking all the registered student id, 0 means the student is removed and new student will be added at that place in future.
    function viewAllStudents() public view returns(uint256 [] memory){
        return allStudents;
    }

// function for marking the attendance for the particular student.
    function markAttendance(uint256 _studentId) public{
        require(studentList[_studentId].age!=0,"Sorry this student id is not registered");
        require(msg.sender==manager,"Only manager can mark the attendance for student");
        studentList[_studentId].attendanceCount++;

        emit attendanceMarked(_studentId, block.timestamp);
    }

// getter function to get the attendance count of a particular student using student id.
    function getStudentAttendanceCount(uint256 _studentId) public view returns(uint256){
        require(studentList[_studentId].age!=0,"Sorry this student id is not registered");
        return studentList[_studentId].attendanceCount;
    }

// function to remove student from the list
    function removeStudent(uint256 _studentId) public{
         require(studentList[_studentId].age!=0,"Sorry this student id is not registered");
         require(msg.sender==manager,"Only manager can remove the student from the list");
         studentList[_studentId].studentName="";
         studentList[_studentId].age=0;
         studentList[_studentId].standard=0;
         studentList[_studentId].attendanceCount=0;
         studentList[_studentId].studentId=0;

         for(uint i=0;i<allStudents.length;i++){
            if(allStudents[i]==_studentId){
                delete allStudents[i];
            }
         }

         emit studentRemoved(_studentId);
    }    



}