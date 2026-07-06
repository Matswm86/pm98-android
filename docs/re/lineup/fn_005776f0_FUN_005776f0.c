// FUN_005776f0  entry=005776f0  size=142 bytes

void __thiscall FUN_005776f0(int param_1,uint param_2)

{
  byte bVar1;
  int iVar2;
  int iVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  int local_8;
  
  local_8 = 0;
  uVar6 = 0;
  uVar5 = param_2;
  do {
    iVar3 = 0;
    for (iVar2 = *(int *)(param_1 + 0x24); iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x100)) {
      if ((*(char *)(iVar2 + 0x19) == 'c') && (*(byte *)(iVar2 + 0x1c) == uVar5)) {
        bVar1 = *(byte *)(iVar2 + 0xa8);
        iVar3 = FUN_00581e60();
        uVar4 = iVar3 * (uint)bVar1;
        if (uVar5 == param_2) {
          if (uVar6 <= uVar4) {
LAB_00577745:
            uVar6 = uVar4;
            local_8 = iVar2;
          }
        }
        else if (uVar4 < uVar6) goto LAB_00577745;
      }
      iVar3 = local_8;
    }
    if (uVar5 == 0) {
      uVar5 = 3;
    }
    else {
      uVar5 = uVar5 - 1;
    }
    uVar6 = 9999;
    if ((iVar3 != 0) || (uVar5 == param_2)) {
      return;
    }
  } while( true );
}


