library PathMappingUtils {
  struct PathMapping {
    mapping (bytes32 => bytes32) branchMask;
    uint8 keyDepth;
  }
  bytes32 constant TOP_BIT_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
  function lookupOrLessThan(PathMapping storage pathMapping, bytes32 key) internal returns (bool success, bytes32 foundKey) {
    uint256 shiftTotal = (pathMapping.keyDepth - 1) * 8;
    for (uint256 i = 0; i <= shiftTotal; i += 8) {
      bytes32 partialKey = foundKey | bytes32(0xff << (shiftTotal - i));
      bytes32 mask = pathMapping.branchMask[partialKey];
      uint8 nextKeyByte = uint8(key[i / 8]);
      if (mask == 0 || (nextKeyByte == 0 && mask & TOP_BIT_MASK == 0)) return (false, bytes32(0));
      uint8 nextByte = _highestBitBinarySearch(mask, nextKeyByte);
      foundKey |= bytes32(uint256(nextByte) << (shiftTotal - i));
    }
    success = true;
  }
  function lookupOrGreaterThan(PathMapping storage pathMapping, bytes32 key) internal returns (bool success, bytes32 foundKey) {
    uint256 shiftTotal = (pathMapping.keyDepth - 1) * 8;
    for (uint256 i = 0; i <= shiftTotal; i += 8) {
      bytes32 partialKey = foundKey | bytes32(0xff << (shiftTotal - i));
      bytes32 mask = pathMapping.branchMask[partialKey];
      uint8 nextKeyByte = uint8(key[i / 8]);
      if (mask == 0 || (nextKeyByte == 0 && mask & TOP_BIT_MASK == 0)) return (false, bytes32(0));
      uint8 nextByte = _lowestBitBinarySearch(mask, nextKeyByte);
      foundKey |= bytes32(uint256(nextByte) << (shiftTotal - i));
    }
    success = true;
  }
  function _highestBitBinarySearch(bytes32 mask, uint8 upperBoundInclusive) internal returns (uint8) {
    if (uint256(mask) & (0x1 << (0xff - uint256(upperBoundInclusive))) != 0) return upperBoundInclusive;
    uint256 lowerBound = 0;
    uint256 upperBound = upperBoundInclusive - 1;
    uint256 diff = upperBound;
    uint256 medianDistance = (diff + 1) / 2;
    uint256 median = medianDistance;
    while (true) {
      if ((((0x1 << (0x100 - upperBound)) - 1) << upperBound) & ((0x1 << (0x100 - median)) - 0x1) & uint256(mask) != 0) lowerBound += medianDistance;
      else upperBound -= medianDistance;
      diff = upperBound - lowerBound;
      if (diff == 0) return uint8(upperBound);
      medianDistance = (diff + 1) / 2;
      median = lowerBound + medianDistance;
    }
  }
  function _lowestBitBinarySearch(bytes32 mask, uint8 lowerBoundInclusive) internal returns (uint8) {
    if (uint256(mask) & (0x1 << (0xff - uint256(lowerBoundInclusive))) != 0) return lowerBoundInclusive;
    uint256 lowerBound = lowerBoundInclusive;
    uint256 upperBound = 0xff;
    uint256 diff = 0xff - lowerBoundInclusive;
    uint256 medianDistance = (diff + 1) / 2;
    uint256 median = medianDistance;
    while (true) {
      if ((((0x1 << (0x100 - upperBound)) - 1) << upperBound) & ((0x1 << (0x100 - median)) - 0x1) & uint256(mask) == 0) upperBound -= medianDistance;
      else lowerBound += medianDistance;
      diff = upperBound - lowerBound;
      if (diff == 0) return uint8(lowerBound);
      medianDistance = (diff + 1) / 2;
      median = lowerBound + medianDistance;
    }
  }
  function markPath(PathMapping storage pathMapping, bytes32 key) internal {
    bytes32 assembledKey = bytes32(0);
    uint256 shiftTotal = (pathMapping.keyDepth - 1) * 8;
    for (uint256 i = 0; i <= shiftTotal; i += 8) {
      bytes32 partialKey = assembledKey | bytes32(0xff << (shiftTotal - i));
      uint8 nextKeyByte = uint8(key[i / 8]);
      bytes32 mask = pathMapping.branchMask[partialKey];
      bytes32 newMask = bytes32(0x1 << (0xff - uint256(nextKeyByte))) | mask;
      if (newMask != mask) pathMapping.branchMask[partialKey] = newMask;
      assembledKey |= bytes32(uint256(nextKeyByte) << (shiftTotal - i));
    }
  }
  function setKeyDepth(PathMapping storage pathMapping, uint256 depth) internal {
    pathMapping.keyDepth = uint8(depth);
  }
}
