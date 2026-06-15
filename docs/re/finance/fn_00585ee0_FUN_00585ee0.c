// FUN_00585ee0  entry=00585ee0  size=182 bytes
// callers/callees expanded one level from seeds

undefined4 __thiscall FUN_00585ee0(uint *param_1,uint param_2)

{
  int iVar1;
  undefined4 *puVar2;
  undefined4 local_204;
  CHAR local_200 [512];
  
  if ((param_2 == 0) || (*param_1 <= param_2)) {
    return 0;
  }
  iVar1 = param_2 * 4;
  if (*(int *)(param_1[1] + iVar1) == 0) {
    puVar2 = operator_new(0x20);
    if (puVar2 == (undefined4 *)0x0) {
      puVar2 = (undefined4 *)0x0;
    }
    else {
      puVar2[1] = param_2;
      *puVar2 = 0xff;
      puVar2[2] = 0;
      puVar2[3] = 0;
      puVar2[4] = 0;
      puVar2[5] = 0;
      puVar2[6] = 0;
      puVar2[7] = 0;
    }
    if (puVar2 == (undefined4 *)0x0) {
      local_204 = 0xffff0002;
      lstrcpyA(local_200,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_204,(ThrowInfo *)&DAT_0063ac98);
    }
    *(undefined4 **)(param_1[1] + iVar1) = puVar2;
  }
  return *(undefined4 *)(param_1[1] + iVar1);
}


