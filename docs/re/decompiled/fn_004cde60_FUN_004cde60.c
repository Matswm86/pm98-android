// FUN_004cde60  entry=004cde60  size=4316 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_004cde60(int param_1,int param_2,int param_3)

{
  int *piVar1;
  int iVar2;
  void *pvVar3;
  undefined2 extraout_var;
  undefined2 uVar4;
  undefined2 extraout_var_00;
  undefined2 extraout_var_01;
  undefined2 extraout_var_02;
  undefined2 extraout_var_03;
  undefined2 extraout_var_04;
  undefined2 extraout_var_05;
  undefined2 extraout_var_06;
  undefined2 extraout_var_07;
  undefined2 extraout_var_08;
  undefined2 extraout_var_09;
  undefined2 extraout_var_10;
  undefined2 extraout_var_11;
  undefined2 extraout_var_12;
  undefined2 extraout_var_13;
  undefined4 local_210;
  CHAR local_20c [512];
  void *pvStack_c;
  undefined *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &DAT_00614a85;
  pvStack_c = ExceptionList;
  ExceptionList = &pvStack_c;
  switch(param_2) {
  case 0:
    ExceptionList = &pvStack_c;
    pvVar3 = operator_new(0x11b0c);
    local_4 = 0xc;
    if (pvVar3 == (void *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1 = (int *)FUN_0047a540();
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b194);
    if (iVar2 == 0) {
joined_r0x004ced2a:
      if (piVar1 != (int *)0x0) {
        (**(code **)(*piVar1 + 0xc))(1);
      }
    }
    else {
      uVar4 = 0;
      if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
        (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
        uVar4 = extraout_var_03;
      }
      *(int **)(param_1 + 0x96ec) = piVar1;
      (**(code **)(*piVar1 + 4))
                (param_1,DAT_0066b194,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
      *(undefined4 *)(param_1 + 0x1928) = 0;
    }
    break;
  case 1:
    ExceptionList = &pvStack_c;
    pvVar3 = operator_new(0x11b0c);
    local_4 = 0xd;
    if (pvVar3 == (void *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1 = (int *)FUN_00484eb0();
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b198);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_04;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b198,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 1;
    break;
  case 2:
    ExceptionList = &pvStack_c;
    pvVar3 = operator_new(0x11b0c);
    local_4 = 0xe;
    if (pvVar3 == (void *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1 = (int *)FUN_0048b260();
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b19c);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_05;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b19c,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 2;
    break;
  case 4:
    ExceptionList = &pvStack_c;
    pvVar3 = operator_new(0x11b38);
    local_4 = 0xf;
    if (pvVar3 == (void *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1 = (int *)FUN_00472600();
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b1a0);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_06;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b1a0,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 4;
    break;
  case 5:
    ExceptionList = &pvStack_c;
    pvVar3 = operator_new(0x12368);
    local_4 = 0x10;
    if (pvVar3 == (void *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1 = (int *)FUN_00469960();
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b1a4);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_07;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b1a4,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 5;
    break;
  case 6:
    ExceptionList = &pvStack_c;
    pvVar3 = operator_new(0x38c8);
    local_4 = 0x11;
    if (pvVar3 == (void *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1 = (int *)FUN_004709e0();
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b1a8);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_08;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b1a8,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 6;
    break;
  case 7:
    ExceptionList = &pvStack_c;
    piVar1 = operator_new(0x1c850);
    if (piVar1 == (int *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      *piVar1 = (int)&PTR_FUN_00627fa8;
      local_4._0_1_ = 0x13;
      local_4._1_3_ = 0;
      piVar1[1] = 0;
      piVar1[2] = 6;
      piVar1[3] = 1;
      FUN_005c52b0();
      piVar1[0x111] = 0;
      piVar1[5] = (int)&PTR_LAB_0062b7b0;
      local_4._0_1_ = 0x14;
      FUN_004ccbe0();
      local_4._0_1_ = 0x15;
      FUN_005c52b0();
      local_4._0_1_ = 0x16;
      FUN_00401cd0();
      local_4._0_1_ = 0x17;
      FUN_005db830();
      piVar1[0xa5b] = (int)&PTR_LAB_00627c50;
      piVar1[0xb6c] = 0;
      piVar1[0xb6d] = 0;
      piVar1[0xb6b] = 0;
      local_4._0_1_ = 0x18;
      FUN_004cc950();
      local_4._0_1_ = 0x19;
      FUN_00435550();
      local_4._0_1_ = 0x1a;
      FUN_00435550();
      local_4._0_1_ = 0x1b;
      FUN_00435550();
      local_4._0_1_ = 0x1c;
      FUN_00435550();
      local_4._0_1_ = 0x1d;
      FUN_004ccde0();
      local_4._0_1_ = 0x1e;
      FUN_00605ee0(piVar1 + 0x1c25,0xc58,2,FUN_004ccf90,FUN_004cd010);
      local_4._0_1_ = 0x1f;
      FUN_00605ee0(piVar1 + 0x2251,0x418,6,FUN_00435590,thunk_FUN_005bc6a0);
      local_4._0_1_ = 0x20;
      FUN_0046b950();
      local_4._0_1_ = 0x21;
      FUN_0046b950();
      local_4._0_1_ = 0x22;
      FUN_0046b950();
      local_4._0_1_ = 0x23;
      FUN_0046b950();
      local_4._0_1_ = 0x24;
      FUN_00605ee0(piVar1 + 0x2f69,0x2860,4,FUN_0046b580,FUN_0046b680);
      local_4._0_1_ = 0x25;
      FUN_00605ee0(piVar1 + 0x57c9,0x1824,2,FUN_0046b750,FUN_0046b800);
      local_4._0_1_ = 0x26;
      FUN_00435550();
      local_4._0_1_ = 0x27;
      FUN_00435550();
      local_4._0_1_ = 0x28;
      FUN_004cd630();
      local_4._0_1_ = 0x29;
      FUN_005bc430();
      local_4._0_1_ = 0x2a;
      FUN_005c9210();
      local_4._0_1_ = 0x2b;
      FUN_00435550();
      local_4 = CONCAT31(local_4._1_3_,0x2c);
      FUN_004ccbb0();
      piVar1[0x7212] = 0;
      *piVar1 = (int)&PTR_FUN_0062b7a0;
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b1b4);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_09;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b1b4,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 7;
    break;
  case 8:
    ExceptionList = &pvStack_c;
    pvVar3 = operator_new(0x11f40);
    local_4 = 0x2e;
    if (pvVar3 == (void *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1 = (int *)FUN_0049e8d0();
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b1b0);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_11;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b1b0,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 8;
    break;
  case 9:
    ExceptionList = &pvStack_c;
    pvVar3 = operator_new(0x11b28);
    local_4 = 0x2d;
    if (pvVar3 == (void *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1 = (int *)FUN_0049b150();
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b1ac);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_10;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b1ac,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 9;
    break;
  case 10:
    ExceptionList = &pvStack_c;
    pvVar3 = operator_new(0x34c4);
    local_4 = 0x2f;
    if (pvVar3 == (void *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1 = (int *)FUN_004a1530();
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b1b8);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_12;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b1b8,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 10;
    break;
  case 0xb:
    ExceptionList = &pvStack_c;
    pvVar3 = operator_new(0x38c8);
    local_4 = 0x30;
    if (pvVar3 == (void *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1 = (int *)FUN_0048d800();
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b1bc);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_13;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b1bc,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 0xb;
    break;
  case 0xc:
    ExceptionList = &pvStack_c;
    piVar1 = operator_new(0x2144);
    if (piVar1 == (int *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1[1] = 1;
      *piVar1 = (int)&PTR_FUN_0062b948;
      local_4._0_1_ = 1;
      local_4._1_3_ = 0;
      piVar1[3] = 0;
      FUN_004cd870();
      local_4 = CONCAT31(local_4._1_3_,2);
      FUN_004cc980();
      piVar1[0x84f] = 0;
      *piVar1 = (int)&PTR_FUN_0062b928;
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b190);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b190,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 0xc;
    break;
  case 0xd:
    ExceptionList = &pvStack_c;
    piVar1 = operator_new(0x2144);
    if (piVar1 == (int *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1[1] = 1;
      *piVar1 = (int)&PTR_FUN_0062b948;
      local_4._0_1_ = 4;
      local_4._1_3_ = 0;
      piVar1[3] = 0;
      FUN_004cd870();
      local_4 = CONCAT31(local_4._1_3_,5);
      FUN_004cc980();
      piVar1[0x84f] = 0;
      *piVar1 = (int)&PTR_FUN_0062b908;
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b194);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_00;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b194,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 0xd;
    break;
  case 0xe:
    ExceptionList = &pvStack_c;
    piVar1 = operator_new(0x2144);
    if (piVar1 == (int *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1[1] = 1;
      *piVar1 = (int)&PTR_FUN_0062b948;
      local_4._0_1_ = 7;
      local_4._1_3_ = 0;
      piVar1[3] = 0;
      FUN_004cd870();
      local_4 = CONCAT31(local_4._1_3_,8);
      FUN_004cc980();
      piVar1[0x84f] = 0;
      *piVar1 = (int)&PTR_FUN_0062b8e8;
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b198);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_01;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b198,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 0xe;
    break;
  case 0xf:
    ExceptionList = &pvStack_c;
    piVar1 = operator_new(0x2144);
    if (piVar1 == (int *)0x0) {
      piVar1 = (int *)0x0;
    }
    else {
      piVar1[1] = 1;
      *piVar1 = (int)&PTR_FUN_0062b948;
      local_4._0_1_ = 10;
      local_4._1_3_ = 0;
      piVar1[3] = 0;
      FUN_004cd870();
      local_4 = CONCAT31(local_4._1_3_,0xb);
      FUN_004cc980();
      piVar1[0x84f] = 0;
      *piVar1 = (int)&PTR_FUN_0062b8c8;
    }
    local_4 = 0xffffffff;
    if (piVar1 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar2 = (**(code **)*piVar1)(param_1,DAT_0066b19c);
    if (iVar2 == 0) goto joined_r0x004ced2a;
    uVar4 = 0;
    if (*(int **)(param_1 + 0x96ec) != (int *)0x0) {
      (**(code **)(**(int **)(param_1 + 0x96ec) + 0xc))(1);
      uVar4 = extraout_var_02;
    }
    *(int **)(param_1 + 0x96ec) = piVar1;
    (**(code **)(*piVar1 + 4))
              (param_1,DAT_0066b19c,1,CONCAT22(uVar4,*(undefined2 *)(param_1 + 0x96f0)));
    *(undefined4 *)(param_1 + 0x1928) = 0xf;
  }
  if (param_3 == 0) goto switchD_004cee83_caseD_3;
  (**(code **)(*(int *)(param_1 + 0x39ec) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x3e04) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x421c) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x4634) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x192c) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x1d44) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x215c) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x4a4c) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x4e64) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x527c) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x2574) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x298c) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x2da4) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x31bc) + 0x114))(0);
  (**(code **)(*(int *)(param_1 + 0x35d4) + 0x114))(0);
  switch(*(undefined4 *)(param_1 + 0x1928)) {
  case 0:
    (**(code **)(*(int *)(param_1 + 0x4a4c) + 0x114))(1);
    break;
  case 1:
    piVar1 = (int *)(param_1 + 0x4e64);
    goto LAB_004cef6d;
  case 2:
    (**(code **)(*(int *)(param_1 + 0x527c) + 0x114))(1);
    break;
  case 4:
    piVar1 = (int *)(param_1 + 0x192c);
    goto LAB_004cef6d;
  case 5:
    (**(code **)(*(int *)(param_1 + 0x1d44) + 0x114))(1);
    break;
  case 6:
    piVar1 = (int *)(param_1 + 0x215c);
    goto LAB_004cef6d;
  case 7:
    piVar1 = (int *)(param_1 + 0x2574);
    goto LAB_004cef6d;
  case 8:
    (**(code **)(*(int *)(param_1 + 0x298c) + 0x114))(1);
    break;
  case 9:
    piVar1 = (int *)(param_1 + 0x2da4);
    goto LAB_004cef6d;
  case 10:
    piVar1 = (int *)(param_1 + 0x31bc);
LAB_004cef6d:
    iVar2 = *piVar1;
LAB_004cef71:
    (**(code **)(iVar2 + 0x114))(1);
    break;
  case 0xb:
    (**(code **)(*(int *)(param_1 + 0x35d4) + 0x114))(1);
    break;
  case 0xc:
    iVar2 = *(int *)(param_1 + 0x39ec);
    goto LAB_004cef71;
  case 0xd:
    (**(code **)(*(int *)(param_1 + 0x3e04) + 0x114))(1);
    break;
  case 0xe:
    iVar2 = *(int *)(param_1 + 0x421c);
    goto LAB_004cef71;
  case 0xf:
    (**(code **)(*(int *)(param_1 + 0x4634) + 0x114))(1);
  }
switchD_004cee83_caseD_3:
  if (*(int *)(param_1 + 0x1928) == param_2) {
    FUN_005bebc0(4);
  }
  ExceptionList = pvStack_c;
  return;
}


