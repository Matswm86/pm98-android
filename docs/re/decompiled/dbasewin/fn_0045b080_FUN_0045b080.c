// FUN_0045b080  entry=0045b080  size=406 bytes

CWnd __thiscall
FUN_0045b080(CWnd *param_1,int param_2,int *param_3,char *param_4,uint param_5,undefined4 param_6,
            undefined4 param_7,int param_8)

{
  CWnd *this;
  CWnd CVar1;
  undefined4 *puVar2;
  int iVar3;
  int iVar4;
  undefined4 local_30;
  undefined4 local_2c;
  int local_28;
  int local_24;
  int local_20 [4];
  int local_10 [4];
  
  iVar3 = param_8;
  iVar4 = param_8;
  FUN_004042e0(&stack0xffffffb8,&param_7);
  CVar1 = FUN_00454200(param_1,param_2,param_3,param_4,param_5,param_6,iVar3,iVar4);
  *(undefined4 *)(param_1 + 0x3f8) = 0;
  *(undefined4 *)(param_1 + 0x3f4) = 0;
  *(undefined4 *)(param_1 + 0x400) = 0;
  param_8 = 0;
  this = param_1 + 0x60;
  puVar2 = (undefined4 *)FUN_004042f0(this,(undefined1 *)&param_6,(byte *)&param_8,0x98);
  *(undefined4 *)(param_1 + 0x404) = *puVar2;
  param_8 = 0xffffff;
  puVar2 = (undefined4 *)FUN_004042f0(this,(undefined1 *)&param_6,(byte *)&param_8,0x82);
  *(undefined4 *)(param_1 + 0x408) = *puVar2;
  param_8 = 0xffffff;
  puVar2 = (undefined4 *)FUN_004042f0(this,(undefined1 *)&param_6,(byte *)&param_8,0x3e);
  *(undefined4 *)(param_1 + 0x40c) = *puVar2;
  param_8 = 0xffffff;
  puVar2 = (undefined4 *)FUN_004042f0(this,(undefined1 *)&param_6,(byte *)&param_8,0xae);
  *(undefined4 *)(param_1 + 0x410) = *puVar2;
  param_8 = 0xffffff;
  puVar2 = (undefined4 *)FUN_004042f0(param_1 + 0x5c,(undefined1 *)&param_6,(byte *)&param_8,0x3e);
  *(undefined4 *)(param_1 + 0x414) = *puVar2;
  *(undefined4 *)(param_1 + 0x3fc) = 6;
  if ((*(uint *)(param_1 + 0xac) & 0x400000) != 0) {
    local_30 = 2;
    local_2c = 2;
    local_28 = (*(int *)(param_1 + 0x80) - *(int *)(param_1 + 0x78)) + -2;
    local_24 = (*(int *)(param_1 + 0x84) - *(int *)(param_1 + 0x7c)) + -2;
    FUN_00404230(param_1 + 0x78,local_20,(int *)(param_1 + 0x78));
    puVar2 = (undefined4 *)FUN_0041f4c0(&local_30,local_10,local_20);
    *(undefined4 *)(param_1 + 0x88) = *puVar2;
    *(undefined4 *)(param_1 + 0x8c) = puVar2[1];
    *(undefined4 *)(param_1 + 0x90) = puVar2[2];
    *(undefined4 *)(param_1 + 0x94) = puVar2[3];
  }
  return CVar1;
}


