// FUN_005c9a30  entry=005c9a30  size=387 bytes

undefined4 __thiscall
FUN_005c9a30(int param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,undefined4 param_5
            ,int param_6)

{
  int *piVar1;
  undefined4 uVar2;
  int iVar3;
  uint3 uVar4;
  undefined4 *puVar5;
  bool bVar6;
  byte unaff_retaddr;
  int *piVar7;
  undefined4 local_78 [17];
  undefined4 uStack_34;
  uint uStack_1c;
  
  *(undefined4 *)(param_1 + 0x20) = param_4;
  FUN_005cb040();
  *(undefined4 *)(param_1 + 0x28) = 0;
  *(undefined4 *)(param_1 + 0x38) = 0;
  *(undefined4 *)(param_1 + 0x2c) = 0;
  *(undefined4 *)(param_1 + 0x3c) = 0;
  local_78[0] = 0;
  *(undefined4 *)(param_1 + 0x30) = param_2;
  *(undefined4 *)(param_1 + 0x18) = param_3;
  *(undefined4 *)(param_1 + 0x34) = param_3;
  *(undefined4 *)(param_1 + 0x14) = param_2;
  *(undefined4 *)(param_1 + 0x1c) = param_2;
  uVar2 = FUN_005e5100(param_2,param_3,*(undefined4 *)(param_1 + 0x20),param_5,param_6);
  piVar7 = (int *)0x0;
  piVar1 = *(int **)(DAT_00674800 + 0x18 + DAT_00674c2c * 0x134);
  iVar3 = (**(code **)(*piVar1 + 0x18))(piVar1,uVar2,local_78);
  if (-1 < iVar3) {
    iVar3 = (**(code **)*piVar7)(piVar7,&DAT_0063a250,(undefined4 *)(param_1 + 4));
    if (-1 < iVar3) {
      if (*(int *)(param_1 + 0x20) == 8) {
        piVar1 = *(int **)(param_1 + 4);
        iVar3 = (**(code **)(*piVar1 + 0x7c))
                          (piVar1,*(undefined4 *)(DAT_00674800 + 0x24 + DAT_00674c2c * 0x134));
        if (iVar3 < 0) goto LAB_005c9b1e;
      }
      bVar6 = true;
      goto LAB_005c9b20;
    }
  }
LAB_005c9b1e:
  bVar6 = false;
LAB_005c9b20:
  if ((bVar6 != false) && (param_6 != -1)) {
    iVar3 = (**(code **)(**(int **)(param_1 + 4) + 0x74))(*(int **)(param_1 + 4),8,&stack0xffffff7c)
    ;
    *(int *)(param_1 + 0x24) = param_6;
    bVar6 = -1 < iVar3;
  }
  uVar2 = 0;
  if (piVar7 != (int *)0x0) {
    uVar2 = (**(code **)(*piVar7 + 8))(piVar7);
  }
  uVar4 = (uint3)((uint)uVar2 >> 8);
  *(undefined1 *)(param_1 + 0x48) = 0;
  *(undefined1 *)(param_1 + 0x4b) = 0;
  if ((unaff_retaddr & 1) != 0) {
    puVar5 = (undefined4 *)&stack0xffffff84;
    for (iVar3 = 0x1b; iVar3 != 0; iVar3 = iVar3 + -1) {
      *puVar5 = 0;
      puVar5 = puVar5 + 1;
    }
    uStack_34 = 0x20;
    (**(code **)(**(int **)(param_1 + 4) + 0x58))(*(int **)(param_1 + 4),&stack0xffffff84);
    uVar4 = (uint3)(uStack_1c >> 0x13);
    *(byte *)(param_1 + 0x4b) = ~(byte)(uStack_1c >> 0xb) & 1;
  }
  return CONCAT31(uVar4,bVar6);
}


