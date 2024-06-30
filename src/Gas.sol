// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

contract GasContract {
    /// Type Declarations

    struct ImportantStruct {
        uint256 amount;
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
        bool paymentStatus;
        address sender;
    }

    /// State variables

    mapping(address => uint256) public balances;
    address private contractOwner;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    mapping(address => ImportantStruct) public whiteListStruct;

    /// Events

    event AddedToWhitelist(address userAddress, uint256 tier);
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

    /// Constructor

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;

        for (uint256 i = 0; i < administrators.length; i++) {
            if (_admins[i] != address(0)) {
                administrators[i] = _admins[i];
                if (_admins[i] == contractOwner) {
                    balances[contractOwner] = _totalSupply;
                } else {
                    balances[_admins[i]] = 0;
                }
            }
        }
    }

    /// Functions

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

    function getPaymentStatus(
        address sender
    ) external view returns (bool, uint256) {
        return (
            whiteListStruct[sender].paymentStatus,
            whiteListStruct[sender].amount
        );
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) external {
        require(
            balances[msg.sender] >= _amount && bytes(_name).length < 9,
            "Gas Contract Transfer: Insufficient Balance or Name is too long"
        );
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) external onlyAdminOrOwner {
        require(_tier < 255, "Gas Contract addToWhitelist: Invalid tier");
        if (_tier >= 3) {
            whitelist[_userAddrs] = 3;
        } else {
            whitelist[_userAddrs] = _tier;
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) external {
        uint256 usersTier = whitelist[msg.sender];
        require(
            usersTier > 0 && usersTier < 4,
            "Gas Contract WhiteTransfer : user is not whitelisted"
        );
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
            "Gas Contract whiteTransfer: Insufficient Balance"
        );

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        balances[msg.sender] += usersTier;
        balances[_recipient] -= usersTier;

        emit WhiteListTransfer(_recipient);
    }
}
