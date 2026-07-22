// FUN_00441ea0  entry=00441ea0  size=1837 bytes

void FUN_00441ea0(void)

{
  undefined4 *puVar1;
  void *pvVar2;
  int iVar3;
  undefined4 uVar4;
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00609396;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  puVar1 = operator_new(0xb4);
  local_4 = 0;
  if (puVar1 == (undefined4 *)0x0) {
    puVar1 = (undefined4 *)0x0;
  }
  else {
    FUN_00442770(0);
    local_4 = CONCAT31(local_4._1_3_,1);
    *(undefined1 *)((int)puVar1 + 0xa2) = 0;
    *(undefined1 *)((int)puVar1 + 0xa3) = 0;
    *(undefined2 *)(puVar1 + 0x28) = 0;
    FUN_00442800();
    *puVar1 = &PTR_FUN_00623aa8;
    FUN_0041c0c0();
  }
  local_4 = 0xffffffff;
  if (puVar1 == (undefined4 *)0x0) {
    local_210 = 0xffff0002;
    lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  DAT_0066b190 = puVar1;
  puVar1 = operator_new(0xe0);
  local_4 = 2;
  if (puVar1 == (undefined4 *)0x0) {
    puVar1 = (undefined4 *)0x0;
  }
  else {
    FUN_00442770(1);
    local_4._0_1_ = 3;
    *(undefined1 *)((int)puVar1 + 0x9a) = 0;
    *(undefined1 *)((int)puVar1 + 0x9b) = 0;
    *(undefined2 *)(puVar1 + 0x26) = 0;
    FUN_00442800();
    FUN_00605ee0(puVar1 + 0x2b,8,2,&LAB_00442810,FUN_00410a50);
    local_4._0_1_ = 4;
    FUN_004459f0(0);
    local_4 = CONCAT31(local_4._1_3_,5);
    FUN_00404a80(puVar1 + 0x31,4,2,FUN_00442800);
    FUN_00442800();
    *puVar1 = &PTR_FUN_006238d0;
    FUN_00410210();
  }
  local_4 = 0xffffffff;
  if (puVar1 == (undefined4 *)0x0) {
    local_210 = 0xffff0002;
    lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  DAT_0066b194 = puVar1;
  puVar1 = operator_new(0xe4);
  local_4 = 6;
  if (puVar1 == (undefined4 *)0x0) {
    puVar1 = (undefined4 *)0x0;
  }
  else {
    FUN_00442770(2);
    local_4._0_1_ = 7;
    *(undefined1 *)((int)puVar1 + 0x9e) = 0;
    *(undefined1 *)((int)puVar1 + 0x9f) = 0;
    *(undefined2 *)(puVar1 + 0x27) = 0;
    FUN_00442800();
    FUN_00605ee0(puVar1 + 0x2c,8,2,&LAB_00442810,FUN_00410a50);
    local_4._0_1_ = 8;
    FUN_004459f0(0);
    local_4 = CONCAT31(local_4._1_3_,9);
    FUN_00404a80(puVar1 + 0x32,4,2,FUN_00442800);
    FUN_00442800();
    *puVar1 = &PTR_FUN_00623c40;
    FUN_004250c0();
  }
  local_4 = 0xffffffff;
  if (puVar1 == (undefined4 *)0x0) {
    FUN_00445c70(&DAT_00666f70,0xffff0002);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  DAT_0066b198 = puVar1;
  puVar1 = operator_new(0xd0);
  local_4 = 10;
  if (puVar1 == (undefined4 *)0x0) {
    puVar1 = (undefined4 *)0x0;
  }
  else {
    FUN_00442770(3);
    local_4._0_1_ = 0xb;
    FUN_00442800();
    FUN_00605ee0(puVar1 + 0x27,8,2,&LAB_00442810,FUN_00410a50);
    local_4._0_1_ = 0xc;
    FUN_004459f0(0);
    local_4 = CONCAT31(local_4._1_3_,0xd);
    FUN_00404a80(puVar1 + 0x2d,4,2,FUN_00442800);
    FUN_00442800();
    *puVar1 = &PTR_FUN_00623dd8;
    FUN_0042e880();
  }
  local_4 = 0xffffffff;
  if (puVar1 == (undefined4 *)0x0) {
    FUN_00445c70(&DAT_00666f70,0xffff0002);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  DAT_0066b19c = puVar1;
  pvVar2 = operator_new(0x144);
  local_4 = 0xe;
  if (pvVar2 == (void *)0x0) {
    iVar3 = 0;
  }
  else {
    iVar3 = FUN_00451b30(9);
  }
  local_4 = 0xffffffff;
  if (iVar3 == 0) {
    FUN_00445c70(&DAT_00666f70,0xffff0002);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  DAT_0066b1b4 = iVar3;
  pvVar2 = operator_new(0xa0);
  local_4 = 0xf;
  if (pvVar2 == (void *)0x0) {
    iVar3 = 0;
  }
  else {
    iVar3 = FUN_00457ac0(7);
  }
  local_4 = 0xffffffff;
  if (iVar3 == 0) {
    FUN_00445c70(&DAT_00666f70,0xffff0002);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  DAT_0066b1ac = iVar3;
  pvVar2 = operator_new(0x94);
  local_4 = 0x10;
  if (pvVar2 == (void *)0x0) {
    iVar3 = 0;
  }
  else {
    iVar3 = FUN_0045dfb0(8);
  }
  local_4 = 0xffffffff;
  if (iVar3 == 0) {
    FUN_00445c70(&DAT_00666f70,0xffff0002);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  DAT_0066b1b0 = iVar3;
  pvVar2 = operator_new(0x20);
  local_4 = 0x11;
  if (pvVar2 == (void *)0x0) {
    iVar3 = 0;
  }
  else {
    iVar3 = FUN_004631a0(10);
  }
  local_4 = 0xffffffff;
  if (iVar3 == 0) {
    FUN_00445c70(&DAT_00666f70,0xffff0002);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  DAT_0066b1b8 = iVar3;
  pvVar2 = operator_new(0x30);
  local_4 = 0x12;
  if (pvVar2 == (void *)0x0) {
    iVar3 = 0;
  }
  else {
    iVar3 = FUN_0043d0b0(0xd);
  }
  local_4 = 0xffffffff;
  if (iVar3 == 0) {
    FUN_00445c70(&DAT_00666f70,0xffff0002);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  DAT_0066b1c4 = iVar3;
  pvVar2 = operator_new(0x18);
  local_4 = 0x13;
  if (pvVar2 == (void *)0x0) {
    iVar3 = 0;
  }
  else {
    iVar3 = FUN_00431b30(0xb);
  }
  local_4 = 0xffffffff;
  if (iVar3 == 0) {
    FUN_00445c70(&DAT_00666f70,0xffff0002);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  DAT_0066b1bc = iVar3;
  puVar1 = operator_new(0x20);
  if (puVar1 == (undefined4 *)0x0) {
    puVar1 = (undefined4 *)0x0;
  }
  else {
    *puVar1 = &PTR_LAB_00626e80;
    *(undefined2 *)(puVar1 + 7) = 0xc;
    puVar1[1] = 0;
    puVar1[2] = 0;
    puVar1[3] = 0;
    puVar1[4] = 0;
    puVar1[6] = 0;
    puVar1[5] = 0;
  }
  if (puVar1 == (undefined4 *)0x0) {
    FUN_00445c70(&DAT_00666f70,0xffff0002);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  DAT_0066b1c0 = puVar1;
  pvVar2 = operator_new(0x1cc);
  local_4 = 0x14;
  if (pvVar2 == (void *)0x0) {
    iVar3 = 0;
  }
  else {
    iVar3 = FUN_00442820(4);
  }
  local_4 = 0xffffffff;
  if (iVar3 == 0) {
    FUN_00445c70(&DAT_00666f70,0xffff0002);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  DAT_0066b1a0 = iVar3;
  pvVar2 = operator_new(0x150);
  local_4 = 0x15;
  if (pvVar2 == (void *)0x0) {
    uVar4 = 0;
  }
  else {
    uVar4 = FUN_00442d70(5);
  }
  local_4 = 0xffffffff;
  DAT_0066b1a4 = FUN_00470670(uVar4);
  pvVar2 = operator_new(0x18);
  local_4 = 0x16;
  if (pvVar2 == (void *)0x0) {
    uVar4 = 0;
  }
  else {
    uVar4 = FUN_004430d0(6);
  }
  local_4 = 0xffffffff;
  DAT_0066b1a8 = FUN_00470670(uVar4);
  puVar1 = &DAT_0066b190;
  do {
    (**(code **)(*(int *)*puVar1 + 0x9c))();
    puVar1 = puVar1 + 1;
  } while ((int)puVar1 < 0x66b1c8);
  ExceptionList = local_c;
  return;
}


