// FUN_004ece00  entry=004ece00  size=81 bytes

void __thiscall FUN_004ece00(undefined2 *param_1,undefined4 *param_2)

{
  undefined1 uVar1;
  undefined1 uVar2;
  undefined2 uVar3;
  undefined1 *puVar4;
  
  if ((*(byte *)(param_2 + 3) & 1) == 0) {
    param_2 = (undefined4 *)0xffffffff;
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&param_2,(ThrowInfo *)&DAT_0063ab88);
  }
  puVar4 = (undefined1 *)*param_2;
  uVar1 = *puVar4;
  *param_2 = puVar4 + 1;
  uVar2 = puVar4[1];
  *param_2 = puVar4 + 2;
  uVar3 = *(undefined2 *)(puVar4 + 2);
  *param_2 = puVar4 + 4;
  *param_1 = uVar3;
  *(undefined1 *)((int)param_1 + 3) = uVar2;
  *(undefined1 *)(param_1 + 1) = uVar1;
  return;
}


