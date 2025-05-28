// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Identity Management
 * @dev A smart contract for managing decentralized identities witredential verification
 * @author Decentralized Identity Management Team
 */
contract DecentralizedIdentityManagement
    // Structure to store identity information
    struct Identity {
        string name;
        string email;
        bool isVerified;
        uint256 createdAt;
        address owner;
        mapping(string => string) credentials; // credential type => credential hash
        string[] credentialTypes;
    }
    
    // Structure for credential verification requests
    struct VerificationRequest {
        address identityOwner;
        string credentialType;
        string credentialHash;
        address verifier;
        bool isApproved;
        bool exists;
        uint256 requestedAt;
    }
    
    // Mappings
    mapping(address => Identity) private identities;
    mapping(address => bool) public hasIdentity;
    mapping(address => bool) public authorizedVerifiers;
    mapping(bytes32 => VerificationRequest) public verificationRequests;
    
    // Events
    event IdentityCreated(address indexed owner, string name, uint256 timestamp);
    event CredentialAdded(address indexed owner, string credentialType, uint256 timestamp);
    event VerificationRequested(bytes32 indexed requestId, address indexed owner, string credentialType);
    event CredentialVerified(bytes32 indexed requestId, address indexed owner, string credentialType, bool approved);
    event VerifierAuthorized(address indexed verifier, uint256 timestamp);
    event VerifierRevoked(address indexed verifier, uint256 timestamp);
    
    // Modifiers
    modifier onlyIdentityOwner() {
        require(hasIdentity[msg.sender], "Identity does not exist");
        require(identities[msg.sender].owner == msg.sender, "Not the identity owner");
        _;
    }
    
    modifier onlyAuthorizedVerifier() {
        require(authorizedVerifiers[msg.sender], "Not an authorized verifier");
        _;
    }
    
    modifier identityExists(address _owner) {
        require(hasIdentity[_owner], "Identity does not exist");
        _;
    }
    
    // Contract owner for managing verifiers
    address public contractOwner;
    
    constructor() {
        contractOwner = msg.sender;
        authorizedVerifiers[msg.sender] = true; // Contract owner is a default verifier
    }
    
    /**
     * @dev Create a new decentralized identity
     * @param _name Full name of the identity owner
     * @param _email Email address of the identity owner
     */
    function createIdentity(string memory _name, string memory _email) external {
        require(!hasIdentity[msg.sender], "Identity already exists");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_email).length > 0, "Email cannot be empty");
        
        Identity storage newIdentity = identities[msg.sender];
        newIdentity.name = _name;
        newIdentity.email = _email;
        newIdentity.isVerified = false;
        newIdentity.createdAt = block.timestamp;
        newIdentity.owner = msg.sender;
        
        hasIdentity[msg.sender] = true;
        
        emit IdentityCreated(msg.sender, _name, block.timestamp);
    }
    
    /**
     * @dev Add a credential to the identity
     * @param _credentialType Type of credential (e.g., "education", "employment", "certification")
     * @param _credentialHash Hash of the credential data for verification
     */
    function addCredential(string memory _credentialType, string memory _credentialHash) external onlyIdentityOwner {
        require(bytes(_credentialType).length > 0, "Credential type cannot be empty");
        require(bytes(_credentialHash).length > 0, "Credential hash cannot be empty");
        
        Identity storage identity = identities[msg.sender];
        
        // Check if credential type already exists
        bool typeExists = false;
        for (uint i = 0; i < identity.credentialTypes.length; i++) {
            if (keccak256(bytes(identity.credentialTypes[i])) == keccak256(bytes(_credentialType))) {
                typeExists = true;
                break;
            }
        }
        
        // Add credential type to array if it doesn't exist
        if (!typeExists) {
            identity.credentialTypes.push(_credentialType);
        }
        
        // Store the credential hash
        identity.credentials[_credentialType] = _credentialHash;
        
        emit CredentialAdded(msg.sender, _credentialType, block.timestamp);
    }
    
    /**
     * @dev Verify a credential for an identity
     * @param _identityOwner Address of the identity owner
     * @param _credentialType Type of credential to verify
     * @param _isApproved Whether the credential is approved or not
     * @param _requestId Unique request ID for this verification request
     */
    function verifyCredential(
        address _identityOwner, 
        string memory _credentialType, 
        bool _isApproved,
        bytes32 _requestId
    ) external onlyAuthorizedVerifier identityExists(_identityOwner) {
        require(verificationRequests[_requestId].exists, "Verification request does not exist");
        require(!verificationRequests[_requestId].isApproved || !_isApproved, "Credential already verified");
        
        Identity storage identity = identities[_identityOwner];
        require(bytes(identity.credentials[_credentialType]).length > 0, "Credential does not exist");
        
        // Update verification request
        verificationRequests[_requestId].isApproved = _isApproved;
        verificationRequests[_requestId].verifier = msg.sender;
        
        // If approved, mark identity as verified
        if (_isApproved) {
            identity.isVerified = true;
        }
        
        emit CredentialVerified(_requestId, _identityOwner, _credentialType, _isApproved);
    }
    
    // Additional utility functions
    
    /**
     * @dev Request verification for a credential
     * @param _credentialType Type of credential to be verified
     * @param _credentialHash Hash of the credential for verification
     * @return requestId Unique identifier for the verification request
     */
    function requestVerification(string memory _credentialType, string memory _credentialHash) external onlyIdentityOwner returns (bytes32) {
        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, _credentialType, block.timestamp));
        
        verificationRequests[requestId] = VerificationRequest({
            identityOwner: msg.sender,
            credentialType: _credentialType,
            credentialHash: _credentialHash,
            verifier: address(0),
            isApproved: false,
            exists: true,
            requestedAt: block.timestamp
        });
        
        emit VerificationRequested(requestId, msg.sender, _credentialType);
        return requestId;
    }
    
    /**
     * @dev Get identity information (public view)
     * @param _owner Address of the identity owner
     * @return name The full name of the identity owner
     * @return email The email address of the identity owner
     * @return isVerified Whether the identity has been verified
     * @return createdAt The timestamp when the identity was created
     */
    function getIdentity(address _owner) external view identityExists(_owner) returns (
        string memory name,
        string memory email,
        bool isVerified,
        uint256 createdAt
    ) {
        Identity storage identity = identities[_owner];
        return (identity.name, identity.email, identity.isVerified, identity.createdAt);
    }
    
    /**
     * @dev Get credential types for an identity
     * @param _owner Address of the identity owner
     * @return Array of credential types
     */
    function getCredentialTypes(address _owner) external view identityExists(_owner) returns (string[] memory) {
        return identities[_owner].credentialTypes;
    }
    
    /**
     * @dev Authorize a new verifier (only contract owner)
     * @param _verifier Address to be authorized as verifier
     */
    function authorizeVerifier(address _verifier) external {
        require(msg.sender == contractOwner, "Only contract owner can authorize verifiers");
        require(_verifier != address(0), "Invalid verifier address");
        
        authorizedVerifiers[_verifier] = true;
        emit VerifierAuthorized(_verifier, block.timestamp);
    }
    
    /**
     * @dev Revoke verifier authorization (only contract owner)
     * @param _verifier Address to revoke authorization from
     */
    function revokeVerifier(address _verifier) external {
        require(msg.sender == contractOwner, "Only contract owner can revoke verifiers");
        require(_verifier != contractOwner, "Cannot revoke contract owner");
        
        authorizedVerifiers[_verifier] = false;
        emit VerifierRevoked(_verifier, block.timestamp);
    }
}
