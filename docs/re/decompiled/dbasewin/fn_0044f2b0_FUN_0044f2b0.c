// FUN_0044f2b0  entry=0044f2b0  size=486 bytes

char __thiscall
FUN_0044f2b0(void *this,uint param_1,char param_2,byte param_3,int param_4,int param_5,int param_6,
            int param_7,int *param_8,int *param_9,int param_10,int param_11,undefined4 param_12)

{
  char cVar1;
  undefined4 uVar2;
  ushort uVar3;
  int *piVar4;
  int *piVar5;
  ushort uVar6;
  int local_a4 [19];
  int local_58 [19];
  void *local_c;
  undefined1 *puStack_8;
  uint local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00482903;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_0044c790(local_58);
  local_4 = 0;
  FUN_0044c790(local_a4);
  piVar4 = param_9;
  local_4 = CONCAT31(local_4._1_3_,1);
  piVar5 = param_8;
  if ((param_1 & 3) != 0) {
    FUN_0045ce90(local_58,param_8,param_1 & 3);
    piVar5 = local_58;
  }
  uVar6 = (ushort)param_12;
  if ((param_1 & 0x20) == 0) {
    if ((param_1 & 0x10) != 0) {
      uVar3 = uVar6;
      if (param_2 != '\0') {
        uVar3 = 0x100;
      }
      FUN_0045cd60(local_a4,piVar5,uVar3);
      goto LAB_0044f394;
    }
  }
  else {
    uVar3 = uVar6;
    if (param_2 != '\0') {
      uVar3 = 0x100;
    }
    uVar2 = FUN_0045cd60(local_a4,piVar5,0x100);
    if ((char)uVar2 != '\0') {
      FUN_0045c710(local_a4,uVar3);
    }
LAB_0044f394:
    piVar4 = local_a4;
  }
  if (param_2 == '\0') {
LAB_0044f3bf:
    if (piVar4 != (int *)0x0) {
      cVar1 = FUN_0045b890(this,&param_4,piVar4,&param_10,piVar5,&param_10);
      goto LAB_0044f452;
    }
  }
  else if (piVar4 != (int *)0x0) {
    FUN_0045cc00(local_a4,piVar4,param_2,param_3,uVar6);
    piVar4 = local_a4;
    goto LAB_0044f3bf;
  }
  if (uVar6 < 0x100) {
    cVar1 = FUN_0045bbb0(this,&param_4,uVar6,piVar5,&param_10);
  }
  else {
    cVar1 = FUN_0044ee60(this,param_4,param_5,param_6,param_7,piVar5,param_10,param_11);
  }
LAB_0044f452:
  local_4 = local_4 & 0xffffff00;
  thunk_FUN_0044e5d0(local_a4);
  local_4 = 0xffffffff;
  thunk_FUN_0044e5d0(local_58);
  ExceptionList = local_c;
  return cVar1;
}


