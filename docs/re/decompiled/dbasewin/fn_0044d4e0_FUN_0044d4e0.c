// FUN_0044d4e0  entry=0044d4e0  size=439 bytes

char __thiscall FUN_0044d4e0(void *this,char *param_1,uint param_2,int param_3)

{
  char cVar1;
  int iVar2;
  LPSTR pCVar3;
  CHAR local_110 [16];
  CHAR local_100 [256];
  
  iVar2 = FUN_004510e0(param_1);
  if (iVar2 == 0) {
    FUN_0044cfb0(this,1,1,8,0,-1);
    return '\0';
  }
  pCVar3 = FUN_004658a0(param_1,local_100,0xfffffffc);
  pCVar3 = CharUpperA(pCVar3);
  lstrcpyA(local_110,pCVar3);
  iVar2 = lstrcmpA(local_110,&DAT_00495904);
  if (iVar2 == 0) {
    cVar1 = FUN_0044d6a0(this,param_1,param_2,param_3);
    return cVar1;
  }
  iVar2 = lstrcmpA(local_110,&DAT_004958fc);
  if (iVar2 == 0) {
    cVar1 = FUN_0044da80(this,param_1,param_2,param_3);
    return cVar1;
  }
  iVar2 = lstrcmpA(local_110,&DAT_004958f4);
  if (iVar2 == 0) {
    cVar1 = FUN_0044dcc0(this,param_1,param_2,param_3);
    return cVar1;
  }
  iVar2 = lstrcmpA(local_110,&DAT_004958ec);
  if (iVar2 == 0) {
    cVar1 = FUN_0044dfb0(this,param_1,param_2,param_3);
    return cVar1;
  }
  iVar2 = lstrcmpA(local_110,&DAT_004958e4);
  if (iVar2 != 0) {
    iVar2 = lstrcmpA(local_110,&DAT_004958dc);
    if (iVar2 != 0) {
      return '\0';
    }
  }
  cVar1 = FUN_0044e260(this,param_1);
  return cVar1;
}


