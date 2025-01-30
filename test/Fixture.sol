// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import "@openzeppelin/foundry-upgrades/src/Upgrades.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {LaunchFactory} from "../src/launchFactory/v1/LaunchFactory.sol";
import {LaunchFactoryV2} from "../src/launchFactory/v2/LaunchFactoryV2.sol";
import {Curation} from "../src/curation/v1/Curation.sol";
import {CurationV2} from "../src/curation/v2/CurationV2.sol";
import "../src/lib/Structs.sol";
import "../src/lib/Events.sol";

contract Fixture is Test {
    LaunchFactory launchFactory;
    Curation curation;

    uint256 tokenIndex = 0;

    MockERC20 curationToken;

    address baseSepoliapositionManager =
        0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;

    address deployer;
    address bob;

    function setUp() public virtual {
        string memory rpcAlias = "base_sepolia";
        string memory rpcUrl = getChain(rpcAlias).rpcUrl;
        vm.createSelectFork(rpcUrl);

        deployer = makeAddr("deployer");
        bob = makeAddr("bob");

        curationToken = new MockERC20();
        curationToken.initialize("Curation Token", "CURT", 18);

        curation = new Curation();
        launchFactory = LaunchFactory(deployFactory(address(curation)));
    }

    function createNewToken(
        address _mintTo,
        uint256 _mintAmount
    ) public returns (address) {
        string memory tokenName = string(
            abi.encodePacked("New Token:", Strings.toString(tokenIndex))
        );
        string memory tokenSymbol = string(
            abi.encodePacked("NEWT:", Strings.toString(tokenIndex))
        );

        MockERC20 _newToken = new MockERC20();
        _newToken.initialize(tokenName, tokenSymbol, 18);

        deal(address(_newToken), _mintTo, _mintAmount);

        _newToken.approve(address(launchFactory), type(uint256).max);

        return address(_newToken);
    }

    function deployFactory(address _curation) public returns (address proxy) {
        proxy = Upgrades.deployTransparentProxy(
            "LaunchFactory.sol",
            deployer,
            abi.encodeCall(
                LaunchFactory.initialize,
                (deployer, _curation, baseSepoliapositionManager)
            )
        );
    }

    function upgradeFactory(
        address _proxy,
        string memory _newImplementationContractName,
        bytes memory _data
    ) public {
        Upgrades.upgradeProxy(
            _proxy,
            _newImplementationContractName,
            _data,
            deployer
        );
    }

    function createSubmission(
        address _mintTo
    ) public returns (address curationInstance) {
        return
            launchFactory.createSubmission(getSampleCurationDetails(_mintTo));
    }

    /*//////////////////////////////////////////////////////////////
                                 UTILS
    //////////////////////////////////////////////////////////////*/
    function createCurationDetails(
        address _newToken,
        uint256 _distributionAmount,
        uint256 _targetAmount,
        uint256 _liqudityAmount
    ) internal view returns (CurationDetails memory curationDetails) {
        curationDetails = CurationDetails({
            curationToken: IERC20(address(curationToken)),
            newToken: IERC20(address(_newToken)),
            distributionAmount: _distributionAmount,
            targetAmount: _targetAmount,
            liquidityAmount: _liqudityAmount,
            creator: msg.sender
        });
    }

    function getSampleCurationDetails(
        address _to
    ) internal returns (CurationDetails memory curationDetails) {
        address _newToken = createNewToken(_to, 1_000_000 ether);

        curationDetails = createCurationDetails(
            _newToken,
            100_000 ether,
            500_000 ether,
            200_000 ether
        );
    }
}
