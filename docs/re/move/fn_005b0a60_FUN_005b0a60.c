// FUN_005b0a60  entry=005b0a60  size=124 bytes

bool __fastcall FUN_005b0a60(int param_1)

{
  bool bVar1;
  
  bVar1 = false;
  switch(*(undefined4 *)(param_1 + 0x40)) {
  case 0xd:
    return 0 < *(int *)(param_1 + 0x2c);
  case 0x13:
    return *(int *)(param_1 + 0x2c) < 5;
  case 0x1f:
  case 0x21:
  case 0x2f:
    return true;
  case 0x28:
  case 0x29:
  case 0x2c:
  case 0x2d:
    return 3 < *(int *)(param_1 + 0x2c);
  case 0x2e:
    return 1 < *(int *)(param_1 + 0x2c);
  case 0x30:
  case 0x33:
  case 0x34:
    bVar1 = 6 < *(int *)(param_1 + 0x2c);
    break;
  case 0x36:
    return *(int *)(param_1 + 0x2c) < 0x14;
  case 0x37:
    return *(int *)(param_1 + 0x2c) < 6;
  }
  return bVar1;
}


