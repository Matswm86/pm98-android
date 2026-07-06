// FUN_00587030  entry=00587030  size=205 bytes

void __thiscall FUN_00587030(uint *param_1,undefined4 param_2)

{
  char cVar1;
  uint uVar2;
  undefined4 *puVar3;
  uint uVar4;
  undefined4 *puVar5;
  undefined4 local_204;
  CHAR local_200 [512];
  
  cVar1 = FUN_00587140(param_2);
  if (cVar1 == '\0') {
    if (param_1[2] <= *param_1) {
      uVar2 = param_1[2] + 0x10;
      param_1[2] = uVar2;
      puVar3 = operator_new(uVar2 * 4);
      if (puVar3 == (undefined4 *)0x0) {
        local_204 = 0xffff0002;
        lstrcpyA(local_200,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_204,(ThrowInfo *)&DAT_0063ac98);
      }
      uVar2 = param_1[1];
      uVar4 = 0;
      if (*param_1 != 0) {
        puVar5 = puVar3;
        do {
          uVar4 = uVar4 + 1;
          *puVar5 = *(undefined4 *)((uVar2 - (int)puVar3) + (int)puVar5);
          puVar5 = puVar5 + 1;
        } while (uVar4 < *param_1);
      }
      if (uVar4 < param_1[2]) {
        puVar5 = puVar3 + uVar4;
        do {
          *puVar5 = 0;
          uVar4 = uVar4 + 1;
          puVar5 = puVar5 + 1;
        } while (uVar4 < param_1[2]);
      }
      operator_delete((void *)param_1[1]);
      param_1[1] = (uint)puVar3;
    }
    *(undefined4 *)(param_1[1] + *param_1 * 4) = param_2;
    *param_1 = *param_1 + 1;
  }
  return;
}


