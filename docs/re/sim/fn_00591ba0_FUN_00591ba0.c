// FUN_00591ba0  entry=00591ba0  size=1981 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_00591ba0(undefined4 *param_1)

{
  int iVar1;
  int iVar2;
  undefined **ppuVar3;
  int iVar4;
  CHAR local_20c [256];
  undefined1 local_10c [256];
  void *local_c;
  undefined1 *puStack_8;
  int local_4;
  
  puStack_8 = &LAB_00620aa6;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *param_1 = &PTR_LAB_006390e0;
  param_1[0x10c] = &PTR_FUN_006390d8;
  local_4 = 0x1f;
  ppuVar3 = &PTR_s_ALIENTO_00663c40;
  do {
    ppuVar3 = ppuVar3 + 5;
    FUN_00590ea0();
  } while ((int)ppuVar3 < 0x663f10);
  while (0 < DAT_00674654) {
    DAT_00674654 = DAT_00674654 + -1;
    if (DAT_00674650 + DAT_00674654 * 0x68 != 0) {
      FUN_005a1d10(1);
    }
  }
  FUN_005bbf10(&DAT_00674650,0);
  for (; DAT_00674654 < 0; DAT_00674654 = DAT_00674654 + 1) {
    if (DAT_00674650 + DAT_00674654 * 0x68 != 0) {
      FUN_00592360();
    }
  }
  FUN_005ebfc0();
  if (DAT_00674c28 != '\0') {
    iVar4 = 0;
    do {
      lstrcpyA(local_20c,&DAT_00664ba0);
      FUN_0059a260(iVar4);
      FUN_0051fd00(local_20c);
      FUN_005f6e70(local_10c);
      iVar4 = iVar4 + 1;
    } while (iVar4 < 4);
  }
  FUN_005f6e70(s_redh_bmp_00664b94);
  local_4._0_1_ = 0x1e;
  if (param_1[0x17ec] != 0) {
    FUN_005bbed0(param_1[0x17ec]);
    param_1[0x17ec] = 0;
  }
  param_1[0x17ed] = 0;
  local_4._0_1_ = 0x1d;
  FUN_005bad60();
  local_4._0_1_ = 0x1c;
  FUN_005a1c90();
  local_4._0_1_ = 0x1b;
  FUN_005a1c30();
  local_4._0_1_ = 0x1a;
  FUN_005a1c30();
  local_4._0_1_ = 0x19;
  FUN_005a1c30();
  local_4._0_1_ = 0x18;
  FUN_005a1c30();
  iVar1 = param_1[0xa6d];
  local_4 = CONCAT31(local_4._1_3_,0x17);
  iVar4 = iVar1 + -1;
  param_1[0xa6d] = iVar4;
  while (iVar1 != 0) {
    if (param_1[0xa6c] + iVar4 * 0x13c != 0) {
      FUN_005a1d30(1);
    }
    iVar1 = param_1[0xa6d];
    iVar4 = iVar1 + -1;
    param_1[0xa6d] = iVar4;
  }
  if (param_1[0xa6c] != 0) {
    FUN_005bbed0(param_1[0xa6c]);
    param_1[0xa6c] = 0;
  }
  param_1[0xa6d] = 0;
  iVar1 = param_1[0xa54];
  local_4 = CONCAT31(local_4._1_3_,0x16);
  iVar4 = iVar1 + -1;
  param_1[0xa54] = iVar4;
  while (iVar1 != 0) {
    if (param_1[0xa53] + iVar4 * 0x13c != 0) {
      FUN_005a1d30(1);
    }
    iVar1 = param_1[0xa54];
    iVar4 = iVar1 + -1;
    param_1[0xa54] = iVar4;
  }
  if (param_1[0xa53] != 0) {
    FUN_005bbed0(param_1[0xa53]);
    param_1[0xa53] = 0;
  }
  param_1[0xa54] = 0;
  iVar1 = param_1[0xa3b];
  local_4 = CONCAT31(local_4._1_3_,0x15);
  iVar4 = iVar1 + -1;
  param_1[0xa3b] = iVar4;
  while (iVar1 != 0) {
    if (param_1[0xa3a] + iVar4 * 0x13c != 0) {
      FUN_005a1d30(1);
    }
    iVar1 = param_1[0xa3b];
    iVar4 = iVar1 + -1;
    param_1[0xa3b] = iVar4;
  }
  if (param_1[0xa3a] != 0) {
    FUN_005bbed0(param_1[0xa3a]);
    param_1[0xa3a] = 0;
  }
  param_1[0xa3b] = 0;
  iVar1 = param_1[0xa22];
  local_4 = CONCAT31(local_4._1_3_,0x14);
  iVar4 = iVar1 + -1;
  param_1[0xa22] = iVar4;
  while (iVar1 != 0) {
    if (param_1[0xa21] + iVar4 * 0x13c != 0) {
      FUN_005a1d30(1);
    }
    iVar1 = param_1[0xa22];
    iVar4 = iVar1 + -1;
    param_1[0xa22] = iVar4;
  }
  if (param_1[0xa21] != 0) {
    FUN_005bbed0(param_1[0xa21]);
    param_1[0xa21] = 0;
  }
  param_1[0xa22] = 0;
  local_4._0_1_ = 0x13;
  if (param_1[0x9f9] != 0) {
    FUN_005bbed0(param_1[0x9f9]);
    param_1[0x9f9] = 0;
  }
  param_1[0x9fa] = 0;
  local_4._0_1_ = 0x12;
  if (param_1[0x9f7] != 0) {
    FUN_005bbed0(param_1[0x9f7]);
    param_1[0x9f7] = 0;
  }
  param_1[0x9f8] = 0;
  local_4._0_1_ = 0x11;
  if (param_1[0x9f4] != 0) {
    FUN_005bbed0(param_1[0x9f4]);
    param_1[0x9f4] = 0;
  }
  param_1[0x9f5] = 0;
  iVar1 = param_1[0x9f3];
  local_4._0_1_ = 0x10;
  iVar4 = iVar1 + -1;
  param_1[0x9f3] = iVar4;
  while (iVar2 = iVar4, iVar1 != 0) {
    iVar4 = iVar2 + -1;
    param_1[0x9f3] = iVar4;
    iVar1 = iVar2;
  }
  if (param_1[0x9f2] != 0) {
    FUN_005bbed0(param_1[0x9f2]);
    param_1[0x9f2] = 0;
  }
  param_1[0x9f3] = 0;
  local_4._0_1_ = 0x21;
  if (param_1[0x9f0] != 0) {
    FUN_005bbed0(param_1[0x9f0]);
    param_1[0x9f0] = 0;
  }
  param_1[0x9f1] = 0;
  local_4._0_1_ = 0x20;
  if (param_1[0x9e1] != 0) {
    FUN_005bbed0(param_1[0x9e1]);
    param_1[0x9e1] = 0;
  }
  param_1[0x9e2] = 0;
  local_4._0_1_ = 0xf;
  thunk_FUN_005cb040();
  local_4._0_1_ = 0xe;
  FUN_00605da0(param_1 + 0x967,0x4c,2,thunk_FUN_005cb040);
  local_4._0_1_ = 0xd;
  thunk_FUN_005cb040();
  local_4._0_1_ = 0xc;
  thunk_FUN_005cb040();
  local_4._0_1_ = 0xb;
  thunk_FUN_005cb040();
  local_4._0_1_ = 10;
  FUN_00605da0(param_1 + 0x91c,8,9,FUN_00591830);
  iVar1 = param_1[0x91b];
  local_4 = CONCAT31(local_4._1_3_,9);
  iVar4 = iVar1 + -1;
  param_1[0x91b] = iVar4;
  while (iVar1 != 0) {
    if (iVar4 * 0x4c + param_1[0x91a] != 0) {
      FUN_005a1d20(1);
    }
    iVar1 = param_1[0x91b];
    iVar4 = iVar1 + -1;
    param_1[0x91b] = iVar4;
  }
  if (param_1[0x91a] != 0) {
    FUN_005bbed0(param_1[0x91a]);
    param_1[0x91a] = 0;
  }
  param_1[0x91b] = 0;
  local_4._0_1_ = 8;
  if (param_1[0x695] != 0) {
    FUN_005bbed0(param_1[0x695]);
    param_1[0x695] = 0;
  }
  param_1[0x696] = 0;
  local_4._0_1_ = 7;
  if (param_1[0x691] != 0) {
    FUN_005bbed0(param_1[0x691]);
    param_1[0x691] = 0;
  }
  param_1[0x692] = 0;
  local_4._0_1_ = 6;
  if (param_1[0x689] != 0) {
    FUN_005bbed0(param_1[0x689]);
    param_1[0x689] = 0;
  }
  param_1[0x68a] = 0;
  local_4._0_1_ = 5;
  if (param_1[0x5fd] != 0) {
    FUN_005bbed0(param_1[0x5fd]);
    param_1[0x5fd] = 0;
  }
  param_1[0x5fe] = 0;
  local_4._0_1_ = 0x22;
  if (param_1[0x5fb] != 0) {
    FUN_005bbed0(param_1[0x5fb]);
    param_1[0x5fb] = 0;
  }
  param_1[0x5fc] = 0;
  local_4._0_1_ = 4;
  if (param_1[0x592] != 0) {
    FUN_005bbed0(param_1[0x592]);
    param_1[0x592] = 0;
  }
  param_1[0x593] = 0;
  local_4._0_1_ = 0x24;
  if (param_1[0x57b] != 0) {
    FUN_005bbed0(param_1[0x57b]);
    param_1[0x57b] = 0;
  }
  param_1[0x57c] = 0;
  local_4._0_1_ = 0x23;
  thunk_FUN_005cb040();
  local_4._0_1_ = 3;
  if (param_1[0x49d] != 0) {
    FUN_005bbed0(param_1[0x49d]);
    param_1[0x49d] = 0;
  }
  param_1[0x49e] = 0;
  local_4._0_1_ = 0x26;
  if (param_1[0x489] != 0) {
    FUN_005bbed0(param_1[0x489]);
    param_1[0x489] = 0;
  }
  param_1[0x48a] = 0;
  local_4._0_1_ = 0x25;
  thunk_FUN_005cb040();
  local_4._0_1_ = 2;
  if (param_1[0x3ab] != 0) {
    FUN_005bbed0(param_1[0x3ab]);
    param_1[0x3ab] = 0;
  }
  param_1[0x3ac] = 0;
  local_4._0_1_ = 0x28;
  if (param_1[0x397] != 0) {
    FUN_005bbed0(param_1[0x397]);
    param_1[0x397] = 0;
  }
  param_1[0x398] = 0;
  local_4._0_1_ = 0x27;
  thunk_FUN_005cb040();
  local_4._0_1_ = 1;
  if (param_1[0x2b9] != 0) {
    FUN_005bbed0(param_1[0x2b9]);
    param_1[0x2b9] = 0;
  }
  param_1[0x2ba] = 0;
  local_4 = (uint)local_4._1_3_ << 8;
  FUN_00605da0(param_1 + 0x11b,800,2,FUN_00591560);
  local_4 = 0xffffffff;
  FUN_005c5410();
  ExceptionList = local_c;
  return;
}


