// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract zero2hero {

    // errors
    error NotSuperAdmin();
    error NotAnAdmin();
    error AddressZero();
    error ExistingMember();
    error EmptyInput();
    error IsAnAdmin();
    error NotAMember();
    error InvalidOrderID();

    // State Variables
    address superAdmin;
    mapping (address => bool) isAdmin;
    mapping (address => bool) isRegistered;
    mapping (address => string) username;
    uint buyTracker;
    uint sellTracker;
    mapping (bytes32 => address) initiator;
    mapping (bytes32 => bool) pendingBuyOrder;
    mapping (bytes32 => bool) pendingSellOrder;
    mapping (bytes32 => bool) successfulBuyOrder;
    mapping (bytes32 => bool) successfulSellOrder;
    mapping (bytes32 => bool) unsuccessfulBuyOrder;
    mapping (bytes32 => bool) unsuccessfulSellOrder;

    // Modifiers
    modifier isTheSuperAdmin(address _superAdmin) {
        if (superAdmin != _superAdmin) revert NotSuperAdmin();
        _;
    }

    modifier isAnAdmin(address _admin) {
        if (isAdmin[_admin] == false) revert NotAnAdmin();
        _;
    }

    modifier noEmptiness(string memory name) {
        if (bytes(name).length == 0) revert EmptyInput();
        _;
    }

    // Events
    event SuperAdminChange(address indexed _previousAdmin, address indexed _newSuperAdmin);

    event NewAdmin(address indexed _superAdmin, address indexed _newAdmin);

    event RevokeAdmin(address indexed _superAdmin, address indexed revokedAdmin);

    event Register(address indexed _user, string indexed _username);

    event BuyOrder(address indexed _buyer, bytes32 indexed _orderID);

    event SellOrder(address indexed _seller, bytes32 indexed _orderID);

    event SuccessfulBuy(address indexed _admin, address indexed _buyer, bytes32 indexed _orderID);

    event SuccessfulSell(address indexed _admin, address indexed _seller, bytes32 indexed _orderID);

    event UnsuccessfulBuy(address indexed _admin, address indexed _buyer, bytes32 indexed _orderID);

    event UnsuccessfulSell(address indexed _admin, address indexed _seller, bytes32 indexed _orderID);

    // Constructor
    constructor() {
        superAdmin = msg.sender;
    }

    // Functions
    function changeSuperAdmin(address _newSuperAdmin) isTheSuperAdmin(msg.sender) external {
        if (_newSuperAdmin == address(0) || _newSuperAdmin == superAdmin) revert AddressZero();
        superAdmin = _newSuperAdmin;
        emit SuperAdminChange(msg.sender, _newSuperAdmin);
    }

    function makeAdmin(address _newAdmin) isTheSuperAdmin(msg.sender) external {
        if (_newAdmin == address(0)) revert AddressZero();
        isAdmin[_newAdmin] = true;
        emit NewAdmin(msg.sender, _newAdmin);
    }

    function revokeAdmin (address _admin) isTheSuperAdmin(msg.sender) external {
        isAdmin[_admin] = false;
        emit RevokeAdmin(msg.sender, _admin);
    }

    function register (string memory _username) noEmptiness(_username) external {
        if (isRegistered[msg.sender]) revert ExistingMember();
        isRegistered[msg.sender] = true;
        username[msg.sender] = _username;
        emit Register(msg.sender, _username);
    }

    function buyOrder () external returns (bytes32) {
        if (isRegistered[msg.sender] == false) revert NotAMember();
        if (isAdmin[msg.sender] || msg.sender == superAdmin) revert IsAnAdmin();
        buyTracker = buyTracker++;
        bytes32 orderID = keccak256(abi.encode("buyOrder", buyTracker));
        pendingBuyOrder[orderID] = true;
        initiator[orderID] = msg.sender;
        emit BuyOrder(msg.sender, orderID);
        return orderID;
    }

    function sellOrder () external returns (bytes32) {
        if (isRegistered[msg.sender] == false) revert NotAMember();
        if (isAdmin[msg.sender] || msg.sender == superAdmin) revert IsAnAdmin();
        sellTracker = sellTracker++;
        bytes32 orderID = keccak256(abi.encode("sellOrder", sellTracker));
        pendingSellOrder[orderID] = true;
        initiator[orderID] = msg.sender;
        emit SellOrder(msg.sender, orderID);
        return orderID;
    }

    function succesfulBuy (bytes32 _orderID) external {
        if (msg.sender != superAdmin || isAdmin[msg.sender] == false) revert NotAnAdmin();
        if (pendingBuyOrder[_orderID] != true || unsuccessfulBuyOrder[_orderID]) revert InvalidOrderID();
        pendingBuyOrder[_orderID] = false;
        successfulBuyOrder[_orderID] = true;
        emit SuccessfulBuy(msg.sender, initiator[_orderID], _orderID);
    }

    function unsuccesfulBuy (bytes32 _orderID) external {
        if (msg.sender != superAdmin || isAdmin[msg.sender] == false) revert NotAnAdmin();
        if (pendingBuyOrder[_orderID] != true || successfulBuyOrder[_orderID]) revert InvalidOrderID();
        pendingBuyOrder[_orderID] = false;
        unsuccessfulBuyOrder[_orderID] = true;
        emit UnsuccessfulBuy(msg.sender, initiator[_orderID], _orderID);
    }

    function succesfulSell (bytes32 _orderID) external {
        if (msg.sender != superAdmin || isAdmin[msg.sender] == false) revert NotAnAdmin();
        if (pendingSellOrder[_orderID] != true || unsuccessfulSellOrder[_orderID]) revert InvalidOrderID();
        pendingSellOrder[_orderID] = false;
        successfulSellOrder[_orderID] = true;
        emit SuccessfulSell(msg.sender, initiator[_orderID], _orderID);
    }

    function unsuccesfulSell (bytes32 _orderID) external {
        if (msg.sender != superAdmin || isAdmin[msg.sender] == false) revert NotAnAdmin();
        if (pendingSellOrder[_orderID] != true || successfulSellOrder[_orderID]) revert InvalidOrderID();
        pendingSellOrder[_orderID] = false;
        unsuccessfulSellOrder[_orderID] = true;
        emit UnsuccessfulSell(msg.sender, initiator[_orderID], _orderID);
    }

    function checkBuyOrderStatus (bytes32 _orderID) external view returns (string memory) {
        if (pendingBuyOrder[_orderID]){
            return "Pending";
        } else if (successfulBuyOrder[_orderID]){
            return "Succesful";
        }else if (unsuccessfulBuyOrder[_orderID]){
            return "Unsuccessful";
        }else return "Invalid ID";
    }

    function checkSellOrderStatus (bytes32 _orderID) external view returns (string memory) {
        if (pendingSellOrder[_orderID]){
            return "Pending";
        } else if (successfulSellOrder[_orderID]){
            return "Succesful";
        }else if (unsuccessfulSellOrder[_orderID]){
            return "Unsuccessful";
        }else return "Invalid ID";
    }

}