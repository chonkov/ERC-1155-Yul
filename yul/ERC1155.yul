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
        v := keccak256(0x00, 0x20)
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

      // function decodeAsArray(pointer) -> size,firstSlot {
      //   size := calldataload(add(4, pointer))
      //   if lt(calldatasize(), add(pointer, mul(size, 0x20))) {
      //       revert(0, 0)
      //     }
      //   firstSlot := add(0x24, pointer)
      // }

      function calculateDoubleMapping(slot, key1, key2) -> v {
        v := hash(hash(slot, key1), key2)
      }

      function mint(to, id, amount) {
        let slot := calculateDoubleMapping(balances(), to, id)
        sstore(slot, amount)
      }

      function setApprovalForAll(operator, isApproved) {
        let slot := calculateDoubleMapping(operatorApprovals(), caller(), operator)
        sstore(slot, isApproved)
      }

      function balanceOf(owner, id) -> v {
        let offset := calculateDoubleMapping(balances(), owner, id)
        v := sload(offset)
      }

      function isApprovedForAll(owner, operator) -> v {
        let offset := calculateDoubleMapping(operatorApprovals(), owner, operator)
        v := sload(offset)
      }
    }
   }
 }