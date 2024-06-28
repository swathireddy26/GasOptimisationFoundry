// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

contract GasContract {
    /// Type Declarations

    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct History {
        uint256 lastUpdate;
        uint256 blockNumber;
        address updatedBy;
    }

    struct ImportantStruct {
        uint256 amount;
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
        bool paymentStatus;
        address sender;
    }

    /// State variables

    uint256 public immutable totalSupply = 0; // cannot be updated
    uint256 public paymentCounter = 0;
    mapping(address => uint256) public balances;
    address public contractOwner;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    mapping(address => ImportantStruct) public whiteListStruct;

    /// Events

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    /// Errors

    /// Modfiers

    modifier onlyAdminOrOwner() {
        if (checkForAdmin(msg.sender)) {
            _;
        } else if (msg.sender == contractOwner) {
            _;
        } else {
            revert(
                "Gas Contract onlyAdminOrOwner: Caller neither admin nor owner"
            );
        }
    }

    modifier checkIfWhiteListed(address sender) {
        uint256 usersTier = whitelist[sender];
        require(
            usersTier > 0 && usersTier < 4,
            "Gas Contract CheckIfWhiteListed modifier : user is not whitelisted"
        );
        _;
    }

    /// Constructor

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 i = 0; i < administrators.length; i++) {
            if (_admins[i] != address(0)) {
                administrators[i] = _admins[i];
                if (_admins[i] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                    emit supplyChanged(_admins[i], totalSupply);
                } else {
                    balances[_admins[i]] = 0;
                    emit supplyChanged(_admins[i], 0);
                }
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        bool admin = false;
        for (uint256 i = 0; i < administrators.length; i++) {
            if (administrators[i] == _user) {
                admin = true;
            }
        }
        return admin;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        require(
            balances[msg.sender] >= _amount,
            "Gas Contract Transfer: Insufficient Balance"
        );
        require(
            bytes(_name).length < 9,
            "Gas Contract Transfer: Name is too long"
        );
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        Payment memory payment = Payment(
            PaymentType.BasicPayment,
            ++paymentCounter,
            false,
            _name,
            _recipient,
            address(0),
            _amount
        );
        payments[msg.sender].push(payment);

        return true;
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyAdminOrOwner {
        require(_tier < 255, "Gas Contract addToWhitelist: Invalid tier");
        if (_tier >= 3) {
            whitelist[_userAddrs] = 3;
        } else {
            whitelist[_userAddrs] = _tier;
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender) {
        whiteListStruct[msg.sender] = ImportantStruct(
            _amount,
            0,
            0,
            0,
            true,
            msg.sender
        );

        require(
            balances[msg.sender] >= _amount && _amount > 3,
            "Gas Contract whiteTransfers: Insufficient Balance"
        );

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        balances[msg.sender] += whitelist[msg.sender];
        balances[_recipient] -= whitelist[msg.sender];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (
            whiteListStruct[sender].paymentStatus,
            whiteListStruct[sender].amount
        );
    }
}
