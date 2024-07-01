// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

contract GasContract {
    /// Type Declarations

    struct PaymentStatus {
        uint256 amount;
        bool paymentStatus;
    }

    /// State variables

    mapping(address => uint256) public balances;
    address private immutable contractOwner;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    mapping(address => PaymentStatus) private paymentStatus;

    /// Events

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    /// Errors
    error InvalidTier();
    error UnAuthorized();
    error UserNotWhitelisted();

    /// Modfiers

    /// Constructor

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        balances[contractOwner] = _totalSupply;

        for (uint256 i = 0; i < administrators.length; i++) {
            if (_admins[i] != address(0)) {
                administrators[i] = _admins[i];
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

    function balanceOf(address _user) external view returns (uint256 balance_) {
        return balances[_user];
    }

    function getPaymentStatus(
        address sender
    ) external view returns (bool, uint256) {
        return (
            paymentStatus[sender].paymentStatus,
            paymentStatus[sender].amount
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

    function addToWhitelist(address _userAddrs, uint256 _tier) external {
        if (checkForAdmin(msg.sender) || msg.sender == contractOwner) {
            if (_tier >= 255) {
                revert InvalidTier();
            }
            whitelist[_userAddrs] = (_tier >= 3) ? 3 : _tier;
            emit AddedToWhitelist(_userAddrs, _tier);
        } else {
            revert UnAuthorized();
        }
    }

    function whiteTransfer(address _recipient, uint256 _amount) external {
        uint256 usersTier = whitelist[msg.sender];
        if (usersTier <= 0 || usersTier >= 4) {
            revert UserNotWhitelisted();
        }
        paymentStatus[msg.sender] = PaymentStatus(_amount, true);

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
