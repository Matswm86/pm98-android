// FUN_005cb2b0  entry=005cb2b0  size=111 bytes
// callers/callees expanded one level from seeds

bool __fastcall FUN_005cb2b0(int *param_1)

{
  int *piVar1;
  int iVar2;
  int unaff_ESI;
  undefined4 *puVar3;
  undefined4 local_6c [4];
  int iStack_5c;
  undefined4 local_24;
  
  puVar3 = local_6c;
  for (iVar2 = 0x1b; iVar2 != 0; iVar2 = iVar2 + -1) {
    *puVar3 = 0;
    puVar3 = puVar3 + 1;
  }
  local_6c[0] = 0x6c;
  local_24 = 0x20;
  FUN_005cb390();
  if ((*param_1 == 0) && (piVar1 = (int *)param_1[1], piVar1 != (int *)0x0)) {
    iVar2 = (**(code **)(*piVar1 + 100))(piVar1,0,local_6c,1,0);
    if (-1 < iVar2) {
      param_1[7] = unaff_ESI;
      *param_1 = iStack_5c;
    }
  }
  return *param_1 != 0;
}


