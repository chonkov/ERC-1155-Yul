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
        // batchMint(decodeAsAddress(0), decodeAsArray(1), decodeAsArray(2))
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
            revert(0, 0)
          }
      }

      function getSlot(slot, key1, key2) -> v {
        v := hash(key2, hash(slot, key1))
      }

      function mint(to, id, amount) {
        let slot := getSlot(balances(), to, id)
        sstore(slot, amount)
      }

      function safeTransferFrom(from, to, id, amount) {
        if iszero(or(eq(caller(), from), isApprovedForAll(from, caller()))) {
          revert(0x00, 0x00)
        }

        if iszero(to) {
          revert(0x00, 0x00)
        }

        _safeTransferFrom(from, to, id, amount)

        _onERC1155Received(from, to, id, amount)
      }

      function _safeTransferFrom(from, to, id, amount) {
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

      function _onERC1155Received(from, to, id, amount) {
        if eq(extcodesize(to), 0x00) { return(0x00, 0x00) }

        mstore(0x00, 0x39150de800000000000000000000000000000000000000000000000000000000)
        mstore(0x04, caller())
        mstore(0x24, from)
        mstore(0x44, id)
        mstore(0x64, amount)

        let success := call(gas(), to, 0x00, 0x00, 0x84, 0x00, 0x00)
        returndatacopy(0x00, 0x00, returndatasize())

        if iszero(success) { revert(0x00, 0x00) }
        // 0x39150de8 != 0xf23a6e61
        if iszero(eq(shr(0xe0, mload(0x00)), 0xf23a6e61)) {
          revert(0x00, 0x00)
        }
      }

      function setApprovalForAll(operator, isApproved) {
        let slot := getSlot(operatorApprovals(), caller(), operator)
        sstore(slot, isApproved)
      }

      function balanceOf(owner, id) -> v {
        let slot := getSlot(balances(), owner, id)
        v := sload(slot)
      }

      function balanceOfBatch(ownersOffset, idsOffset) -> start, end
      {
        let ownersLength := decodeAsArray(ownersOffset)
        let idsLength := decodeAsArray(idsOffset)

        if iszero(eq(ownersLength, idsLength)) {
          revert(0x00, 0x00)
        }

        // @audit Why If I start from 0x00, the tx reverts (I can start from 0x40) 
        let memPtr := 0x80
        start := memPtr

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
    }
   }
 }