// FUN_005d35d0  entry=005d35d0  size=356 bytes
// callers/callees expanded one level from seeds

undefined4 FUN_005d35d0(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  LPSTR pCVar1;
  int iVar2;
  undefined4 uVar3;
  CHAR local_110 [16];
  undefined1 local_100 [256];
  
  pCVar1 = (LPSTR)FUN_005e5c50(local_100,0xfffffffc);
  pCVar1 = CharUpperA(pCVar1);
  lstrcpyA(local_110,pCVar1);
  iVar2 = lstrcmpA(local_110,&DAT_00665bb4);
  if (iVar2 == 0) {
    uVar3 = FUN_005d3f60(param_1,param_2,param_3);
    return uVar3;
  }
  iVar2 = lstrcmpA(local_110,&DAT_0066578c);
  if (iVar2 == 0) {
    uVar3 = FUN_005d3740(param_1,param_2,param_3);
    return uVar3;
  }
  iVar2 = lstrcmpA(local_110,&DAT_00665bbc);
  if (iVar2 == 0) {
    uVar3 = FUN_005d37e0(param_1,param_2,param_3);
    return uVar3;
  }
  iVar2 = lstrcmpA(local_110,&DAT_00665958);
  if (iVar2 == 0) {
    uVar3 = FUN_005d3880(param_1,param_2,param_3);
    return uVar3;
  }
  iVar2 = lstrcmpA(local_110,&DAT_00665bc4);
  if (iVar2 == 0) {
    uVar3 = FUN_005d3a50(param_1,param_2,param_3);
    return uVar3;
  }
  return 0;
}


