// FUN_00591180  entry=00591180  size=954 bytes
// callers/callees expanded one level from seeds

undefined4 * __fastcall FUN_00591180(undefined4 *param_1)

{
  int iVar1;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00620673;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005c52b0();
  param_1[0x10c] = &PTR_LAB_00639218;
  local_4 = 0;
  param_1[0x119] = 0;
  FUN_00605ee0(param_1 + 0x11b,800,2,FUN_005b6360,FUN_00591560);
  local_4._0_1_ = 1;
  FUN_005a2640(param_1);
  param_1[0x2ab] = &PTR_LAB_00639208;
  param_1[0x39a] = 1;
  param_1[0x359] = 0;
  local_4._0_1_ = 2;
  FUN_005a2640(param_1);
  param_1[0x39d] = &PTR_LAB_00639208;
  param_1[0x48c] = 2;
  param_1[1099] = 0;
  local_4._0_1_ = 3;
  FUN_005a2640(param_1);
  param_1[0x48f] = &PTR_LAB_006391f8;
  param_1[0x53d] = 0;
  local_4._0_1_ = 4;
  FUN_0058e050(param_1);
  param_1[0x5fd] = 0;
  param_1[0x5fe] = 0;
  param_1[0x5ff] = 0xffffffff;
  *(undefined1 *)((int)param_1 + 0x1809) = 0;
  param_1[0x60c] = 0x70000000;
  param_1[0x60b] = 0x70000000;
  param_1[0x60a] = 0x70000000;
  param_1[0x60f] = 0x90000000;
  param_1[0x60e] = 0x90000000;
  param_1[0x60d] = 0x90000000;
  *(undefined1 *)(param_1 + 0x610) = 0;
  *(undefined1 *)((int)param_1 + 0x1a1d) = 0;
  param_1[0x689] = 0;
  param_1[0x68a] = 0;
  param_1[0x691] = 0;
  param_1[0x692] = 0;
  param_1[0x693] = 0;
  param_1[0x694] = 0;
  param_1[0x695] = 0;
  param_1[0x696] = 0;
  param_1[0x697] = 0;
  param_1[0x698] = 0;
  param_1[0x91a] = 0;
  param_1[0x91b] = 0;
  local_4._0_1_ = 0xf;
  FUN_00605ee0(param_1 + 0x91c,8,9,&LAB_005917f0,FUN_00591830);
  local_4._0_1_ = 0x10;
  FUN_005c9210();
  local_4._0_1_ = 0x11;
  FUN_005c9210();
  local_4._0_1_ = 0x12;
  FUN_005c9210();
  local_4._0_1_ = 0x13;
  FUN_00605ee0(param_1 + 0x967,0x4c,2,FUN_005c9210,thunk_FUN_005cb040);
  local_4._0_1_ = 0x14;
  FUN_005d7240();
  param_1[0x9f2] = 0;
  param_1[0x9f3] = 0;
  param_1[0x9f4] = 0;
  param_1[0x9f5] = 0;
  param_1[0x9f7] = 0;
  param_1[0x9f8] = 0;
  param_1[0x9f9] = 0;
  param_1[0x9fa] = 0;
  local_4._0_1_ = 0x1d;
  FUN_005f56a0();
  FUN_005f2ad0();
  local_4._0_1_ = 0x1e;
  FUN_005f2ad0();
  local_4._0_1_ = 0x1f;
  FUN_005f2ad0();
  local_4._0_1_ = 0x20;
  FUN_005f2ad0();
  local_4._0_1_ = 0x21;
  FUN_005f2ad0();
  local_4._0_1_ = 0x22;
  FUN_005f2ad0();
  local_4._0_1_ = 0x23;
  FUN_005f2ad0();
  local_4._0_1_ = 0x24;
  FUN_005f2ad0();
  param_1[0xae9] = 0;
  param_1[0xaea] = 0;
  local_4._0_1_ = 0x27;
  FUN_005baca0();
  param_1[0x17ec] = 0;
  param_1[0x17ed] = 0;
  *param_1 = &PTR_LAB_006390e0;
  param_1[0x10c] = &PTR_FUN_006390d8;
  local_4 = CONCAT31(local_4._1_3_,0x2a);
  FUN_005bbf10(&DAT_00674650,(DAT_00674654 + 1) * 0x68);
  if (DAT_00674650 + DAT_00674654 * 0x68 != 0) {
    FUN_005f50b0(*(undefined4 *)(DAT_00674ea0 + 0x20),1,0x100);
  }
  iVar1 = DAT_00674654 + 2;
  DAT_00674654 = DAT_00674654 + 1;
  FUN_005bbf10(&DAT_00674650,iVar1 * 0x68);
  if (DAT_00674650 + DAT_00674654 * 0x68 != 0) {
    FUN_005f50b0(*(undefined4 *)(DAT_00674ea0 + 0x20),1,0x100);
  }
  DAT_00674654 = DAT_00674654 + 1;
  param_1[0x667] = 0;
  param_1[0x116] = 0;
  *(undefined1 *)(param_1 + 0x17eb) = 0;
  ExceptionList = local_c;
  return param_1;
}


