// FUN_005ec020  entry=005ec020  size=176 bytes
// callers/callees expanded one level from seeds

bool __thiscall FUN_005ec020(LPSTR param_1,LPCSTR param_2)

{
  int iVar1;
  undefined4 local_20c;
  undefined4 local_208;
  undefined4 local_204;
  CHAR local_200 [512];
  
  FUN_005ec0e0();
  FUN_005eaf80(&local_20c,param_2,0,param_1 + 0x110,0,0);
  *(undefined4 *)(param_1 + 0x100) = local_20c;
  *(undefined4 *)(param_1 + 0x104) = local_208;
  iVar1 = *(int *)(param_1 + 0x100);
  *(int *)(param_1 + 0x10c) = iVar1;
  *(int *)(param_1 + 0x108) = iVar1;
  if (iVar1 == 0) {
    local_204 = 0xffff0001;
    lstrcpyA(local_200,param_2);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_204,(ThrowInfo *)&DAT_0063ac98);
  }
  lstrcpyA(param_1,param_2);
  return *(int *)(param_1 + 0x108) != 0;
}


