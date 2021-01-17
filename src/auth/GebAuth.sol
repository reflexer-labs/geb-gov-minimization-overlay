pragma solidity 0.6.7;

contract GebAuth {
    // --- Authorities ---
    mapping (address => uint) public authorizedAccounts;
    function addAuthorization(address account) external isAuthorized { authorizedAccounts[account] = 1; emit AddAuthorization(account); }
    function removeAuthorization(address account) external isAuthorized { authorizedAccounts[account] = 0; emit RemoveAuthorization(account); }
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "GebAuth/not-an-authority");
        _;
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);

    constructor () public {
        authorizedAccounts[msg.sender] = 1;
        emit AddAuthorization(msg.sender);
    }
}
