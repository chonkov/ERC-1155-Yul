object "ERC1155" {
   code {
     datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
     return(0, datasize("Runtime"))
   }
   object "Runtime" {
     code {
      //// Storage setup
      function balances() -> slot { slot := 0x00 }
      function operatorApprovals() -> slot { slot := 0x01 }

      ///////////////////////////////////////////////////////////////////////////////////////////////////
      ///                                                                                             ///
      ///                                         Dispatcher                                          ///
      ///                                                                                             ///
      ///////////////////////////////////////////////////////////////////////////////////////////////////
      switch selector()
      ///////////////////////////////////////////////////////////////////////////////////////////////////
      ///                                                                                             ///
      ///                                         Mint/BatchMint                                      ///
      ///                                                                                             ///
      ///////////////////////////////////////////////////////////////////////////////////////////////////
      // mint(address,uint256,uint256,bytes)
      case 0x731133e9 {
        mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
        returnTrue()
      }
      // batchMint(address,uint256[],uint256[],bytes)
      case 0xb48ab8b6 {
        batchMint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
        returnTrue()
      }
      ///////////////////////////////////////////////////////////////////////////////////////////////////
      ///                                                                                             ///
      ///                                         Write functions                                     ///
      ///                                                                                             ///
      ///////////////////////////////////////////////////////////////////////////////////////////////////
      // safeTransferFrom(address,address,uint256,uint256,bytes)
      case 0xf242432a {
        safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3))
        returnTrue()
      }
      // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
      case 0x2eb2c2d6 {
        safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3))
        returnTrue()
      }
      // setApprovalForAll(address,bool)
      case 0xa22cb465 {
        setApprovalForAll(decodeAsAddress(0), decodeAsBool(1))
        returnTrue()
      }
      ///////////////////////////////////////////////////////////////////////////////////////////////////
      ///                                                                                             ///
      ///                                         Read functions                                      ///
      ///                                                                                             ///
      ///////////////////////////////////////////////////////////////////////////////////////////////////
      // balanceOf(address,uint256)
      case 0x00fdd58e {
        returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
      }
      // balanceOfBatch(address[],uint256[])
      case 0x4e1273f4 {
        let from, to := balanceOfBatch(decodeAsUint(0), decodeAsUint(1))
        return(from, to)
      }
      // isApprovedForAll(address,address)
      case 0xe985e9c5 {
        returnUint(isApprovedForAll(decodeAsAddress(0), decodeAsAddress(1)))
      }
      ///////////////////////////////////////////////////////////////////////////////////////////////////
      ///                                                                                             ///
      ///                                         Fallback                                            ///
      ///                                                                                             ///
      ///////////////////////////////////////////////////////////////////////////////////////////////////
      default {
        revert (0x00, 0x00)
      }

      ///////////////////////////////////////////////////////////////////////////////////////////////////
      ///                                                                                             ///
      ///                                         Util functions                                      ///
      ///                                                                                             ///
      ///////////////////////////////////////////////////////////////////////////////////////////////////

      function selector() -> signature { signature := shr(0xe0, calldataload(0x00)) }

      function hash(slot, value) -> v {
        mstore(0x00, value)
        mstore(0x20, slot)
        v := keccak256(0x00, 0x40)
      }

      function returnUint(v) {
        mstore(0x00, v)
        return(0x00, 0x20)
      }

      function returnTrue() {
        returnUint(1)
      }

      function decodeAsAddress(offset) -> v {
        v := decodeAsUint(offset)
        if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
          revert(0, 0)
        }
      }

      function decodeAsUint(offset) -> v {
        let pos := add(4, mul(offset, 0x20))
        if lt(calldatasize(), add(pos, 0x20)) {
            revert(0, 0)
          }
        v := calldataload(pos)
      }

      function decodeAsBool(offset) -> v {
        v := decodeAsUint(offset)
        v := and(0x01, v)
      }

      function decodeAsArray(pointer) -> size {
        size := calldataload(add(4, pointer))
        if lt(calldatasize(), add(pointer, mul(size, 0x20))) {
          revert(0x00, 0x00)
        }
      }

      function getSlot(slot, key1, key2) -> v {
        v := hash(key2, hash(slot, key1))
      }

      ///////////////////////////////////////////////////////////////////////////////////////////////////
      ///                                                                                             ///
      ///                                         Implementation of write functions                   ///
      ///                                                                                             ///
      ///////////////////////////////////////////////////////////////////////////////////////////////////

      function mint(to, id, amount) {
        _mint(to, id, amount)

        emitTransferSingle(caller(), 0x00, to, id, amount)

        _onERC1155Received(0xf23a6e6100000000000000000000000000000000000000000000000000000000, 0x00, to, id, amount)
      }

      function batchMint(to, idsOffset, amountsOffset) {
        if eq(to, 0x00) { revert(0x00, 0x00) }

        let idsLength := decodeAsArray(idsOffset)
        let amountsLength := decodeAsArray(amountsOffset)

        if iszero(eq(amountsLength, idsLength)) {
          revert(0x00, 0x00)
        }

        for { let i := 0x00 } lt(i, idsLength) { i := add(i, 0x01) } {
          let iterationOffset := mul(0x20, add(i, 0x01))

          let idOffset := add(iterationOffset, add(0x04, idsOffset))
          let amountOffset := add(iterationOffset, add(0x04, amountsOffset))

          let id := calldataload(idOffset)
          let amount := calldataload(amountOffset)

          _mint(to, id, amount)
        }

        emitTransferBatch(caller(), 0x00, to, idsOffset, amountsOffset)

        _onERC1155BatchReceived(0xbc197c8100000000000000000000000000000000000000000000000000000000, 0x00, to, idsOffset, amountsOffset)
      }

      function safeTransferFrom(from, to, id, amount) {
        _safeTransferFrom(from, to, id, amount)

        emitTransferSingle(caller(), from, to, id, amount)

        _onERC1155Received(0xf23a6e6100000000000000000000000000000000000000000000000000000000, from, to, id, amount)
      }

      function safeBatchTransferFrom(from, to, idsOffset, amountsOffset) {
        let idsLength := decodeAsArray(idsOffset)
        let amountsLength := decodeAsArray(amountsOffset)

        if iszero(eq(amountsLength, idsLength)) {
          revert(0x00, 0x00)
        }

        for { let i := 0x00 } lt(i, idsLength) { i := add(i, 0x01) } {
          let iterationOffset := mul(0x20, add(i, 0x01))

          let idOffset := add(iterationOffset, add(0x04, idsOffset))
          let amountOffset := add(iterationOffset, add(0x04, amountsOffset))

          let id := calldataload(idOffset)
          let amount := calldataload(amountOffset)

          _safeTransferFrom(from, to, id, amount)
        }

        emitTransferBatch(caller(), from, to, idsOffset, amountsOffset)

        _onERC1155BatchReceived(0xbc197c8100000000000000000000000000000000000000000000000000000000, from, to, idsOffset, amountsOffset)
      }

      function setApprovalForAll(operator, isApproved) {
        let slot := getSlot(operatorApprovals(), caller(), operator)
        sstore(slot, isApproved)

        emitApprovalForAll(caller(), operator, isApproved)
      }

      ///////////////////////////////////////////////////////////////////////////////////////////////////
      ///                                                                                             ///
      ///                                         Internal write functions                            ///
      ///                                                                                             ///
      ///////////////////////////////////////////////////////////////////////////////////////////////////

      function _mint(to, id, amount) {
        if eq(to, 0x00) { revert(0x00, 0x00) }

        let slot := getSlot(balances(), to, id)
        let currentBalance := sload(slot)
        amount := add(amount, currentBalance)
        sstore(slot, amount)
      }

      function _safeTransferFrom(from, to, id, amount) {
        if iszero(or(eq(caller(), from), isApprovedForAll(from, caller()))) {
          revert(0x00, 0x00)
        }

        if iszero(to) {
          revert(0x00, 0x00)
        }

        let fromSlot := getSlot(balances(), from, id)
        let toSlot := getSlot(balances(), to, id)

        let fromOld := sload(fromSlot)
        let toOld := sload(toSlot)

        let fromNew := sub(fromOld, amount)
        let toNew := add(toOld, amount)

        if gt(fromNew, fromOld) {
          revert(0x00, 0x00)
        }

        if lt(toNew, toOld) {
          revert(0x00, 0x00)
        }

        sstore(fromSlot, fromNew)
        sstore(toSlot, toNew)
      }

      function _onERC1155BatchReceived(signature, from, to, idsOffset, amountsOffset) {
        if eq(extcodesize(to), 0x00) { leave }

        let idsLength := decodeAsArray(idsOffset)
        let amountsLength := decodeAsArray(amountsOffset)

        let totalLengthOfIds := add(idsLength, 0x01)
        let totalLengthOfAmounts := add(amountsLength, 0x01)

        let _amountsOffset := mul(0x20, totalLengthOfIds)
        let _bytesOffset := add(_amountsOffset, mul(0x20, totalLengthOfAmounts))

        mstore(0x00, signature)
        mstore(0x04, caller())
        mstore(0x24, from)
        mstore(0x44, 0xa0)
        mstore(0x64, add(0xa0, _amountsOffset))
        mstore(0x84, add(0xa0, _bytesOffset))

        let memPtr := 0xa4

        mstore(memPtr, idsLength)
        memPtr := add(memPtr, 0x20)

        for { let i := 0x00 } lt(i, idsLength) { i := add(i, 0x01) } {
          let iterationOffset := mul(0x20, add(i, 0x01))
          let currentIdOffset := add(iterationOffset, add(0x04, idsOffset))
          let id := calldataload(currentIdOffset)

          mstore(memPtr, id)
          memPtr := add(memPtr, 0x20)
        }

        mstore(memPtr, amountsLength)
        memPtr := add(memPtr, 0x20)

        for { let i := 0x00 } lt(i, amountsLength) { i := add(i, 0x01) } {
          let iterationOffset := mul(0x20, add(i, 0x01))
          let currentAmountOffset := add(iterationOffset, add(0x04, amountsOffset))
          let amount := calldataload(currentAmountOffset)

          mstore(memPtr, amount)
          memPtr := add(memPtr, 0x20)
        }

        mstore(memPtr, 0x00)
        memPtr := add(memPtr, 0x20)

        let success := call(gas(), to, 0x00, 0x00, memPtr, 0x00, 0x00)
        returndatacopy(0x00, 0x00, returndatasize())

        if iszero(success) { revert(0x00, 0x00) }
        
        if iszero(eq(mload(0x00), signature)) {
          revert(0x00, 0x00)
        }
      }

      function _onERC1155Received(signature, from, to, id, amount) {
        if eq(extcodesize(to), 0x00) { leave }

        mstore(0x00, signature)
        mstore(0x04, caller())
        mstore(0x24, from)
        mstore(0x44, id)
        mstore(0x64, amount)
        // @fix Currently, only empty data is passed to callback 
        mstore(0x84, 0xa0)
        mstore(0xa4, 0x00)

        let success := call(gas(), to, 0x00, 0x00, 0xc4, 0x00, 0x00)
        returndatacopy(0x00, 0x00, returndatasize())

        if iszero(success) { revert(0x00, 0x00) }
        
        if iszero(eq(mload(0x00), signature)) {
          revert(0x00, 0x00)
        }
      }

      ///////////////////////////////////////////////////////////////////////////////////////////////////
      ///                                                                                             ///
      ///                                         Implementation of read functions                    ///
      ///                                                                                             ///
      ///////////////////////////////////////////////////////////////////////////////////////////////////

      function balanceOf(owner, id) -> v {
        let slot := getSlot(balances(), owner, id)
        v := sload(slot)
      }

      function balanceOfBatch(ownersOffset, idsOffset) -> start, end {
        let ownersLength := decodeAsArray(ownersOffset)
        let idsLength := decodeAsArray(idsOffset)

        if iszero(eq(ownersLength, idsLength)) {
          revert(0x00, 0x00)
        }

        // @audit Why If I start from 0x00, the tx reverts (I can start from 0x40)
        let memPtr := 0x80
        start := memPtr

        // @audit Why should I construct the data in memory as `calldata` & not `memory`
        mstore(memPtr, 0x20) // offset
        memPtr := add(memPtr, 0x20)

        mstore(memPtr, ownersLength)
        memPtr := add(memPtr, 0x20)

        for { let i := 0x00 } lt(i, ownersLength) { i := add(i, 0x01) } {
          let iterationOffset := mul(0x20, add(i, 0x01))
          let currentOwnerOffset := add(iterationOffset, add(0x04, ownersOffset))
          let currentIdOffset := add(iterationOffset, add(0x04, idsOffset))

          let owner := calldataload(currentOwnerOffset)
          let id := calldataload(currentIdOffset)

          let _balance := balanceOf(owner, id)

          mstore(memPtr, _balance)
          memPtr := add(memPtr, 0x20)
        }

        end := memPtr
      }

      function isApprovedForAll(owner, operator) -> v {
        let slot := getSlot(operatorApprovals(), owner, operator)
        v := sload(slot)
      }

      ///////////////////////////////////////////////////////////////////////////////////////////////////
      ///                                                                                             ///
      ///                                         Events                                              ///
      ///                                                                                             ///
      ///////////////////////////////////////////////////////////////////////////////////////////////////

      function emitApprovalForAll(owner, operator, isApproved) {
        let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31

        mstore(0x00, isApproved)
        log3(0x00, 0x20, signatureHash, owner, operator)
      }

      function emitTransferSingle(operator, from, to, id, amount) {
        let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62

        mstore(0x00, id)
        mstore(0x20, amount)

        log4(0x00, 0x40, signatureHash, operator, from, to)
      }

      function emitTransferBatch(operator, from, to, idsOffset, amountsOffset) {
        let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb

        let idsLength := decodeAsArray(idsOffset)
        let amountsLength := decodeAsArray(amountsOffset)

        let memPtr := 0x00

        mstore(memPtr, 0x40)
        memPtr := add(memPtr, 0x20)

        mstore(memPtr, mul(add(amountsLength, 0x03), 0x20))
        memPtr := add(memPtr, 0x20)

        mstore(memPtr, idsLength)
        memPtr := add(memPtr, 0x20)

        for { let i := 0x00 } lt(i, idsLength) { i := add(i, 0x01) } {
          let iterationOffset := mul(0x20, add(i, 0x01))
          let currentIdOffset := add(iterationOffset, add(0x04, idsOffset))
          let id := calldataload(currentIdOffset)

          mstore(memPtr, id)
          memPtr := add(memPtr, 0x20)
        }

        mstore(memPtr, amountsLength)
        memPtr := add(memPtr, 0x20)

        for { let i := 0x00 } lt(i, amountsLength) { i := add(i, 0x01) } {
          let iterationOffset := mul(0x20, add(i, 0x01))
          let currentAmountOffset := add(iterationOffset, add(0x04, amountsOffset))
          let amount := calldataload(currentAmountOffset)

          mstore(memPtr, amount)
          memPtr := add(memPtr, 0x20)
        }

        log4(0x00, memPtr, signatureHash, operator, from, to)
      }
    }
   }
 }