// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/* --------------------------------- Errors -------------------------------- */

error NotOwner();
error TxNotExist();
error TxApproved();
error TxExecuted();
error OwnersRequired();
error InvalidRequiredrOwners();
error InvalidOwner();
error OwnerAdded();
error NotApproved();
error TxFailed();

contract MultiSigWallet{
    /* --------------------------------- Errors -------------------------------- */
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    /* --------------------------------- Struct -------------------------------- */
    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
    }
    
    /* --------------------------------- Variables -------------------------------- */
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;


    /* --------------------------------- Modifiers -------------------------------- */

    /// @notice Si es uno de los owners
    modifier onlyOwner(){
        if(!isOwner[msg.sender]){
            revert NotOwner();
        }
        _;
    }

    /// @notice Si la transaccion no existe
    modifier txExists(uint _txIndex) {
        if(_txIndex > transactions.length){
            revert TxNotExist();
        }
        _;
    }

    /// @notice Si la transaccion esta aprobada
    modifier notApproved(uint _txIndex) {
        if(approved[_txIndex][msg.sender]){
            revert TxApproved();
        }
        _;
    }

    /// @notice Si la transaccion esta ejecutada
    modifier notExecuted(uint _txIndex) {
        if(transactions[_txIndex].executed){
            revert TxExecuted();
        }
        _;
    }

    function unchecked_inc_tjq(uint i) internal pure returns(uint){
      unchecked {
        i++;
      }
      return i;
    }

    constructor(address[] memory _owners, uint _required){
        /// @notice Debe introducirse mas de un owner
        if(_owners.length < 1){
            revert OwnersRequired();
        }
        /// @notice Debe introducirse mas de un owner de requerido pero menos que los owners introducidos 
        if(_required < 1 && _required > _owners.length){
            revert InvalidRequiredrOwners();
        }
        for(uint i; i < _owners.length; i = unchecked_inc_tjq(i)){
            address owner = _owners[i];
            
            /// @notice La direccion del owner no puede ser 0
            if(owner == address(0)){
                revert InvalidOwner();
            }
            /// @notice La direccion no debe repetirse 
            if(isOwner[owner]){
                revert OwnerAdded();
            }

            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    //para recibir pagos
    receive() external payable{
        emit Deposit(msg.sender, msg.value);
    }

    
    function submit_dcK(address _to, uint _value, bytes calldata _data)
        external
        onlyOwner
    {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }

    function approve_4ms(uint _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount_01_(uint _txId) private view returns(uint count){
        for(uint i; i < owners.length; i++){
            if(approved[_txId][owners[i]]){
                count += 1;
            }
        }
    }

    function execute_G5J(uint _txId) external 
        txExists(_txId) 
        notExecuted(_txId)
    {
        if(_getApprovalCount_01_(_txId) < required){
            revert NotApproved(); 
        }
        Transaction storage transaction = transactions[_txId];

        transaction.executed = true;

        (bool succes, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        if(!succes){
            revert TxFailed();
        }

        emit Execute(_txId);
    }

    function revoke_Ir(uint _txId) external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}
