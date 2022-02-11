pragma solidity 0.8.6;


interface ITokenUriResolver {
    /**
     @notice 
     Computes the metadata url.
     @param _tokenId TokenId of the Banny
     @param _amount Lock Amount.
     @param _duration Lock time in seconds.
     @param _lockedUntil Total lock-in period.
     Returns metadata url.
    */ 
    function tokenURI(uint256 _tokenId, uint256 _amount, uint256 _duration, uint256 _lockedUntil) external view returns(string memory);
}