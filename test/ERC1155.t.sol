// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";
import {MyMultiToken} from "../src/ERC1155.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    // custom functions
    function mint(address to, uint256 id, uint256 amount, bytes calldata) external;
    function batchMint(address to, uint256[] calldata id, uint256[] calldata amounts, bytes calldata) external;
}

contract ERC1155Test is Test {
    YulDeployer yulDeployer = new YulDeployer();

    IERC1155 token;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string _value, uint256 indexed _id);

    function setUp() public {
        // token = IERC1155(yulDeployer.deployContract("ERC1155"));
        token = IERC1155(address(new MyMultiToken()));
    }

    function testMint() public {
        ERC1155Recipient recipient = new ERC1155Recipient();

        token.mint(address(recipient), 1, 1000, "");
        console.log("balance for token1 is : ", token.balanceOf(address(recipient), 1));
        assertEq(token.balanceOf(address(recipient), 1), 1000);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    ///                                                                                             ///
    ///                                    ApprovalForAll tests                                     ///
    ///                                                                                             ///
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    function testApproveAll() public {
        token.setApprovalForAll(address(0xBEEF), true);

        assertTrue(token.isApprovedForAll(address(this), address(0xBEEF)));

        token.setApprovalForAll(address(0xBEEF), false);

        assertFalse(token.isApprovedForAll(address(this), address(0xBEEF)));
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    ///                                                                                             ///
    ///                                    balanceOfBatch tests                                     ///
    ///                                                                                             ///
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    function testBatchBalanceOf() public {
        address[] memory tos = new address[](5);
        tos[0] = address(0xBEEF);
        tos[1] = address(0xCAFE);
        tos[2] = address(0xFACE);
        tos[3] = address(0xDEAD);
        tos[4] = address(0xFEED);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        token.mint(address(0xBEEF), 1337, 100, "");
        token.mint(address(0xCAFE), 1338, 200, "");
        token.mint(address(0xFACE), 1339, 300, "");
        token.mint(address(0xDEAD), 1340, 400, "");
        token.mint(address(0xFEED), 1341, 500, "");

        uint256[] memory balances = token.balanceOfBatch(tos, ids);

        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
        assertEq(balances[2], 300);
        assertEq(balances[3], 400);
        assertEq(balances[4], 500);
    }

    function testBalanceOfBatchWithArrayMismatchError() public {
        address[] memory tos = new address[](5);
        tos[0] = address(0xBEEF);
        tos[1] = address(0xCAFE);
        tos[2] = address(0xFACE);
        tos[3] = address(0xDEAD);
        tos[4] = address(0xFEED);

        uint256[] memory ids = new uint256[](4);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;

        vm.expectRevert("owners length != ids length");
        token.balanceOfBatch(tos, ids);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    ///                                                                                             ///
    ///                                         mint tests                                          ///
    ///                                                                                             ///
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    function testMintToEOA() public {
        token.mint(address(0xBEEF), 1337, 1, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 1);
    }

    function testMintToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        token.mint(address(to), 1337, 1, "testing 123");

        assertEq(token.balanceOf(address(to), 1337), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertEq(to.mintData(), "testing 123");
    }

    function testMintToZeroError() public {
        vm.expectRevert("to = 0 address");
        token.mint(address(0), 1337, 100, "");
    }

    function testMintToNonERC155RecipientError() public {
        InvalidERC1155Recipient to = new InvalidERC1155Recipient();

        vm.expectRevert();
        token.mint(address(to), 1337, 100, "");
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    ///                                                                                             ///
    ///                                      batchMint tests                                        ///
    ///                                                                                             ///
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    function testBatchMintToEOA() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(address(this), address(0x0), address(0xBEEF), ids, amounts);
        token.batchMint(address(0xBEEF), ids, amounts, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 100);
        assertEq(token.balanceOf(address(0xBEEF), 1338), 200);
        assertEq(token.balanceOf(address(0xBEEF), 1339), 300);
        assertEq(token.balanceOf(address(0xBEEF), 1340), 400);
        assertEq(token.balanceOf(address(0xBEEF), 1341), 500);
    }

    function testBatchMintToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(address(this), address(0x0), address(to), ids, amounts);

        token.batchMint(address(to), ids, amounts, "testing 123");

        assertEq(to.batchOperator(), address(this));
        assertEq(to.batchFrom(), address(0));
        assertEq(to.batchIds(), ids);
        assertEq(to.batchAmounts(), amounts);
        assertEq(to.batchData(), "testing 123");

        assertEq(token.balanceOf(address(to), 1337), 100);
        assertEq(token.balanceOf(address(to), 1338), 200);
        assertEq(token.balanceOf(address(to), 1339), 300);
        assertEq(token.balanceOf(address(to), 1340), 400);
        assertEq(token.balanceOf(address(to), 1341), 500);
    }

    function testBatchMintToZeroError() public {
        uint256[] memory ids = new uint256[](5);
        uint256[] memory amounts = new uint256[](5);

        vm.expectRevert("to = 0 address");
        token.batchMint(address(0), ids, amounts, "");
    }

    function testBatchMintInvalidInputError() public {
        uint256[] memory ids = new uint256[](5);
        uint256[] memory amounts = new uint256[](4);

        vm.expectRevert("ids length != values length");
        token.batchMint(address(this), ids, amounts, "");
    }

    function testBatchMintToNonERC155RecipientError() public {
        InvalidERC1155Recipient to = new InvalidERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        uint256[] memory amounts = new uint256[](5);

        vm.expectRevert("unsafe transfer");
        token.batchMint(address(to), ids, amounts, "");
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    ///                                                                                             ///
    ///                                   safeTransferFrom tests                                    ///
    ///                                                                                             ///
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), from, address(0xBEEF), 1337, 70);

        token.safeTransferFrom(from, address(0xBEEF), 1337, 70, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 70);
        assertEq(token.balanceOf(from, 1337), 30);
    }

    function testSafeTransferFromToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(this), from, address(to), 1337, 70);

        token.safeTransferFrom(from, address(to), 1337, 70, "testing 123");

        assertEq(to.operator(), address(this));
        assertEq(to.from(), from);
        assertEq(to.id(), 1337);
        assertEq(to.mintData(), "testing 123");

        assertEq(token.balanceOf(address(to), 1337), 70);
        assertEq(token.balanceOf(from, 1337), 30);
    }

    function testSafeTransferFromInsufficientBalanceError() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 70, "");

        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(from, address(this), true);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert();
        token.safeTransferFrom(from, address(0xBEEF), 1337, 100, "");
    }

    function testSafeTransferFromToZeroError() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        vm.prank(from);
        vm.expectRevert();
        token.safeTransferFrom(from, address(0), 1337, 70, "");
    }

    function testSafeTransferFromUnauthorizedCallerError() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        vm.expectRevert();
        token.safeTransferFrom(from, address(this), 1337, 70, "");
    }

    function testTransferFromToNonERC155RecipientError() public {
        address from = address(0xABCD);
        address to = address(new InvalidERC1155Recipient());

        token.mint(from, 1337, 100, "");

        vm.prank(from);
        vm.expectRevert("unsafe transfer");
        token.safeTransferFrom(from, to, 1337, 70, "");
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    ///                                                                                             ///
    ///                                 safeBatchTransferFrom tests                                 ///
    ///                                                                                             ///
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    function testSafeBatchTransferFromToEOA() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(address(this), from, address(0xBEEF), ids, transferAmounts);

        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");

        assertEq(token.balanceOf(from, 1337), 50);
        assertEq(token.balanceOf(address(0xBEEF), 1337), 50);

        assertEq(token.balanceOf(from, 1338), 100);
        assertEq(token.balanceOf(address(0xBEEF), 1338), 100);

        assertEq(token.balanceOf(from, 1339), 150);
        assertEq(token.balanceOf(address(0xBEEF), 1339), 150);

        assertEq(token.balanceOf(from, 1340), 200);
        assertEq(token.balanceOf(address(0xBEEF), 1340), 200);

        assertEq(token.balanceOf(from, 1341), 250);
        assertEq(token.balanceOf(address(0xBEEF), 1341), 250);
    }

    function testSafeBatchTransferFromToERC1155Recipient() public {
        address from = address(0xABCD);

        ERC1155Recipient to = new ERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectEmit(true, true, true, true);
        emit TransferBatch(address(this), address(from), address(to), ids, transferAmounts);

        token.safeBatchTransferFrom(from, address(to), ids, transferAmounts, "testing 123");

        assertEq(to.batchOperator(), address(this));
        assertEq(to.batchFrom(), from);
        assertEq(to.batchIds(), ids);
        assertEq(to.batchAmounts(), transferAmounts);
        assertEq(to.batchData(), "testing 123");

        assertEq(token.balanceOf(from, 1337), 50);
        assertEq(token.balanceOf(address(to), 1337), 50);

        assertEq(token.balanceOf(from, 1338), 100);
        assertEq(token.balanceOf(address(to), 1338), 100);

        assertEq(token.balanceOf(from, 1339), 150);
        assertEq(token.balanceOf(address(to), 1339), 150);

        assertEq(token.balanceOf(from, 1340), 200);
        assertEq(token.balanceOf(address(to), 1340), 200);

        assertEq(token.balanceOf(from, 1341), 250);
        assertEq(token.balanceOf(address(to), 1341), 250);
    }

    function testSafeBatchTransferFromInsufficientBalanceError() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](3);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;

        uint256[] memory mintAmounts = new uint256[](3);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;

        uint256[] memory transferAmounts = new uint256[](3);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 301;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        vm.expectRevert();
        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");
    }

    function testSafeBatchTransferFromToZeroError() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](3);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;

        uint256[] memory mintAmounts = new uint256[](3);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;

        uint256[] memory transferAmounts = new uint256[](3);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        vm.expectRevert("to = 0 address");
        token.safeBatchTransferFrom(from, address(0), ids, transferAmounts, "");
    }

    function testSafeBatchTransferFromInvalidInputError() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](3);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;

        uint256[] memory mintAmounts = new uint256[](3);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;

        uint256[] memory transferAmounts = new uint256[](4);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        vm.expectRevert("ids length != values length");
        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");
    }

    function testSafeBatchTransferFromUnauthorizedCallerError() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](3);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;

        uint256[] memory mintAmounts = new uint256[](3);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;

        uint256[] memory transferAmounts = new uint256[](3);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;

        token.batchMint(from, ids, mintAmounts, "");

        vm.expectRevert("not approved");
        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");
    }

    function testSafeBatchTransferFromToNonERC155RecipientError() public {
        address from = address(0xABCD);
        address to = address(new InvalidERC1155Recipient());

        uint256[] memory ids = new uint256[](3);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;

        uint256[] memory mintAmounts = new uint256[](3);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;

        uint256[] memory transferAmounts = new uint256[](3);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        vm.expectRevert("unsafe transfer");
        token.safeBatchTransferFrom(from, to, ids, transferAmounts, "");
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                             ///
///                                         Other tools                                         ///
///                                                                                             ///
///////////////////////////////////////////////////////////////////////////////////////////////////
contract ERC1155Recipient is ERC1155TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    uint256 public amount;
    bytes public mintData;

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data)
        public
        override
        returns (bytes4)
    {
        operator = _operator;
        from = _from;
        id = _id;
        amount = _amount;
        mintData = _data;

        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    address public batchOperator;
    address public batchFrom;
    uint256[] internal _batchIds;
    uint256[] internal _batchAmounts;
    bytes public batchData;

    function batchIds() external view returns (uint256[] memory) {
        return _batchIds;
    }

    function batchAmounts() external view returns (uint256[] memory) {
        return _batchAmounts;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external override returns (bytes4) {
        batchOperator = _operator;
        batchFrom = _from;
        _batchIds = _ids;
        _batchAmounts = _amounts;
        batchData = _data;

        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

contract InvalidERC1155Recipient is ERC1155TokenReceiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        public
        pure
        override
        returns (bytes4)
    {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }
}
