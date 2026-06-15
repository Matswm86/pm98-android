// FUN_00586d20  entry=00586d20  size=240 bytes

int FUN_00586d20(uint param_1)

{
  undefined4 uVar1;
  int iVar2;
  void *pvVar3;
  int iVar4;
  char local_390 [256];
  undefined1 local_290 [128];
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0062018e;
  local_c = ExceptionList;
  iVar4 = 0;
  if (param_1 < 25000) {
    ExceptionList = &local_c;
    uVar1 = FUN_00584d40(param_1,local_290);
    sprintf(local_390,s_DBDAT_MINIFOTO__s_bmp_00662918,uVar1);
    iVar2 = FUN_0058c770(local_390);
    if (iVar2 != 0) {
      pvVar3 = operator_new(0x4c);
      local_4 = 0;
      if (pvVar3 == (void *)0x0) {
        iVar4 = 0;
      }
      else {
        iVar4 = FUN_005c9210();
      }
      local_4 = 0xffffffff;
      if (iVar4 == 0) {
        local_210 = 0xffff0002;
        lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
      }
      FUN_005c9f60(local_390,0,0xffffffff);
    }
  }
  ExceptionList = local_c;
  return iVar4;
}


