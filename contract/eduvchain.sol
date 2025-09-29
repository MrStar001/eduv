
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TrustPass
 * @dev A decentralized identity verification and trust monitoring system
 */
contract TrustPass {
    
    struct Identity {
        address userAddress;
        string identityHash;
        uint256 trustScore;
        uint256 verificationCount;
        uint256 createdAt;
        bool isActive;
    }
    
    struct VerificationLog {
        address verifier;
        address verified;
        uint256 timestamp;
        string verificationHash;
    }
    
    mapping(address => Identity) public identities;
    mapping(address => VerificationLog[]) public verificationHistory;
    mapping(address => mapping(address => bool)) public hasVerified;
    
    address public owner;
    uint256 public totalIdentities;
    uint256 public totalVerifications;
    
    event IdentityRegistered(address indexed user, string identityHash, uint256 timestamp);
    event IdentityVerified(address indexed verifier, address indexed verified, uint256 newTrustScore);
    event TrustScoreUpdated(address indexed user, uint256 oldScore, uint256 newScore);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier identityExists(address _user) {
        require(identities[_user].isActive, "Identity does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Register a new identity in the TrustPass system
     * @param _identityHash Hash of user's identity credentials
     */
    function registerIdentity(string memory _identityHash) public {
        require(!identities[msg.sender].isActive, "Identity already registered");
        require(bytes(_identityHash).length > 0, "Identity hash cannot be empty");
        
        identities[msg.sender] = Identity({
            userAddress: msg.sender,
            identityHash: _identityHash,
            trustScore: 50, // Initial trust score
            verificationCount: 0,
            createdAt: block.timestamp,
            isActive: true
        });
        
        totalIdentities++;
        
        emit IdentityRegistered(msg.sender, _identityHash, block.timestamp);
    }
    
    /**
     * @dev Verify another user's identity and increase their trust score
     * @param _userToVerify Address of the user being verified
     * @param _verificationHash Hash of verification proof
     */
    function verifyIdentity(address _userToVerify, string memory _verificationHash) 
        public 
        identityExists(msg.sender)
        identityExists(_userToVerify) 
    {
        require(msg.sender != _userToVerify, "Cannot verify yourself");
        require(!hasVerified[msg.sender][_userToVerify], "Already verified this user");
        require(bytes(_verificationHash).length > 0, "Verification hash cannot be empty");
        
        // Record verification
        hasVerified[msg.sender][_userToVerify] = true;
        
        VerificationLog memory newLog = VerificationLog({
            verifier: msg.sender,
            verified: _userToVerify,
            timestamp: block.timestamp,
            verificationHash: _verificationHash
        });
        
        verificationHistory[_userToVerify].push(newLog);
        
        // Update trust score (max 100)
        Identity storage userIdentity = identities[_userToVerify];
        uint256 oldScore = userIdentity.trustScore;
        userIdentity.verificationCount++;
        
        // Increase trust score by 5 points per verification, capped at 100
        if (userIdentity.trustScore < 100) {
            userIdentity.trustScore = userIdentity.trustScore + 5 > 100 
                ? 100 
                : userIdentity.trustScore + 5;
        }
        
        totalVerifications++;
        
        emit IdentityVerified(msg.sender, _userToVerify, userIdentity.trustScore);
        emit TrustScoreUpdated(_userToVerify, oldScore, userIdentity.trustScore);
    }
    
    /**
     * @dev Get detailed identity information for monitoring
     * @param _user Address of the user
     * @return userAddress User's blockchain address
     * @return identityHash Hash of identity credentials
     * @return trustScore Current trust score (0-100)
     * @return verificationCount Number of verifications received
     * @return createdAt Timestamp of registration
     * @return isActive Whether identity is active
     */
    function getIdentityDetails(address _user) 
        public 
        view 
        returns (
            address userAddress,
            string memory identityHash,
            uint256 trustScore,
            uint256 verificationCount,
            uint256 createdAt,
            bool isActive
        ) 
    {
        Identity memory identity = identities[_user];
        return (
            identity.userAddress,
            identity.identityHash,
            identity.trustScore,
            identity.verificationCount,
            identity.createdAt,
            identity.isActive
        );
    }
    
    /**
     * @dev Get verification history count for a user
     * @param _user Address of the user
     * @return Number of verification logs
     */
    function getVerificationHistoryCount(address _user) public view returns (uint256) {
        return verificationHistory[_user].length;
    }
    
    /**
     * @dev Get platform statistics for monitoring
     * @return Total number of registered identities
     * @return Total number of verifications performed
     */
    function getPlatformStats() public view returns (uint256, uint256) {
        return (totalIdentities, totalVerifications);
    }
}
