// FUN_005b5940  entry=005b5940  size=110 bytes

void __fastcall FUN_005b5940(int param_1)

{
  int iVar1;
  
  FUN_00606220();
  iVar1 = *(int *)(param_1 + 0x18c);
  switch(*(undefined4 *)(iVar1 + 0x1a38)) {
  case 1:
switchD_005b595a_caseD_1:
    FUN_005b59f0();
    return;
  case 2:
  case 3:
  case 4:
  case 6:
  case 8:
switchD_005b595a_caseD_2:
    FUN_005b5d70();
    return;
  case 5:
  case 7:
    if (((*(byte *)(iVar1 + 0x461) & 1) != 0) && ((*(byte *)(iVar1 + 0x461) & 6) == 0)) {
      FUN_005b5dd0();
      return;
    }
    FUN_005b60b0();
    return;
  }
  switch(*(undefined4 *)(iVar1 + 0x448)) {
  case 0:
  case 6:
    goto switchD_005b595a_caseD_1;
  default:
    return;
  case 2:
  case 3:
  case 4:
  case 5:
    goto switchD_005b595a_caseD_2;
  case 7:
    FUN_005b6060();
    return;
  }
}


