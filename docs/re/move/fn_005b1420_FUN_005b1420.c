// FUN_005b1420  entry=005b1420  size=209 bytes

undefined1 __fastcall FUN_005b1420(int param_1)

{
  char cVar1;
  bool bVar2;
  undefined1 uVar3;
  
  uVar3 = 1;
  if (param_1 == *(int *)(*(int *)(param_1 + 400) + 0x40)) {
    *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + 1;
  }
  else {
    *(undefined4 *)(param_1 + 0x14c) = 0;
  }
  if (*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) != '\0') {
    cVar1 = FUN_005943b0();
    if (cVar1 != '\0') {
      bVar2 = true;
      goto LAB_005b1472;
    }
  }
  bVar2 = false;
LAB_005b1472:
  if ((bVar2) && (*(char *)(param_1 + 0x5c) != '\0')) {
    bVar2 = true;
  }
  else {
    bVar2 = false;
  }
  if (!bVar2) {
    if ((param_1 == *(int *)(*(int *)(param_1 + 0x184) + 0x204)) &&
       (*(int *)(*(int *)(param_1 + 400) + 0x40) == 0)) {
      FUN_005b0040();
      return 1;
    }
    if (*(int *)(*(int *)(param_1 + 400) + 0x54) != *(int *)(param_1 + 0x2b8)) {
      uVar3 = FUN_005b1500();
      return uVar3;
    }
    uVar3 = FUN_005b1c80();
  }
  return uVar3;
}


