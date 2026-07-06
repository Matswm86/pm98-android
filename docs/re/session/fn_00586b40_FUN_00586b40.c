// FUN_00586b40  entry=00586b40  size=189 bytes

void __thiscall FUN_00586b40(uint *param_1,ushort *param_2)

{
  void *pvVar1;
  uint uVar2;
  int iVar3;
  uint uVar4;
  undefined4 *puVar5;
  undefined4 local_204;
  CHAR local_200 [512];
  
  if (param_2 != (ushort *)0x0) {
    uVar4 = (uint)*param_2;
    if (*param_1 <= uVar4) {
      pvVar1 = operator_new((uVar4 + 1) * 4);
      if (pvVar1 == (void *)0x0) {
        local_204 = 0xffff0002;
        lstrcpyA(local_200,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_204,(ThrowInfo *)&DAT_0063ac98);
      }
      uVar2 = 0;
      if (*param_1 != 0) {
        do {
          uVar2 = uVar2 + 1;
          *(undefined4 *)((int)pvVar1 + uVar2 * 4 + -4) =
               *(undefined4 *)((param_1[2] - 4) + uVar2 * 4);
        } while (uVar2 < *param_1);
      }
      if (uVar2 < uVar4) {
        puVar5 = (undefined4 *)((int)pvVar1 + uVar2 * 4);
        for (iVar3 = uVar4 - uVar2; iVar3 != 0; iVar3 = iVar3 + -1) {
          *puVar5 = 0;
          puVar5 = puVar5 + 1;
        }
      }
      *param_1 = uVar4 + 1;
      operator_delete((void *)param_1[2]);
      param_1[2] = (uint)pvVar1;
    }
    *(ushort **)(param_1[2] + uVar4 * 4) = param_2;
  }
  return;
}


