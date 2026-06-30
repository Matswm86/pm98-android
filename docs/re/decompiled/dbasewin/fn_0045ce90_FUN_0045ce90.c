// FUN_0045ce90  entry=0045ce90  size=683 bytes

undefined1 __thiscall FUN_0045ce90(void *this,int *param_1,uint param_2)

{
  int iVar1;
  uint uVar2;
  uint uVar3;
  bool bVar4;
  undefined1 uVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  undefined1 *puVar9;
  int iVar10;
  uint *puVar11;
  uint *puVar12;
  undefined1 *local_10;
  int local_8;
  
  uVar5 = 0;
  if ((param_2 & 1) == 0) {
    if ((*(int *)((int)this + 4) == 0) && (*(int *)this == 0)) {
      bVar4 = false;
    }
    else {
      bVar4 = true;
    }
    if (((!bVar4) || (*(int *)((int)this + 0x14) != param_1[5])) ||
       (*(int *)((int)this + 0x18) != param_1[6])) {
      FUN_0044cfb0(this,param_1[5],param_1[6],8,0,-1);
    }
    if ((*(int *)this != 0) || (bVar4 = FUN_0044e840(this), bVar4)) {
      bVar4 = true;
    }
    else {
      bVar4 = false;
    }
    if (bVar4) {
      if ((*param_1 != 0) || (bVar4 = FUN_0044e840(param_1), bVar4)) {
        bVar4 = true;
      }
      else {
        bVar4 = false;
      }
      if (bVar4) {
        iVar10 = *(int *)((int)this + 0x1c) * (*(int *)((int)this + 0x18) + -1) + -4 +
                 *(int *)((int)this + 0x14);
        iVar6 = (int)(iVar10 + (iVar10 >> 0x1f & 3U)) >> 2;
        puVar12 = *(uint **)this;
        puVar11 = (uint *)(*param_1 + iVar10);
        if ((param_2 & 2) == 0) {
          uVar2 = param_1[5];
          uVar3 = param_1[6];
          uVar5 = FUN_0044ee60(this,(0 < (int)uVar2) - 1 & uVar2,(0 < (int)uVar3) - 1 & uVar3,
                               uVar2 & ((int)uVar2 < 0) - 1,uVar3 & ((int)uVar3 < 0) - 1,param_1,0,0
                              );
        }
        else {
          do {
            uVar2 = *puVar11;
            puVar11 = puVar11 + -1;
            *puVar12 = uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 |
                       uVar2 << 0x18;
            puVar12 = puVar12 + 1;
            iVar6 = iVar6 + -1;
          } while (iVar6 != 0);
          uVar5 = 1;
        }
        if ((param_2 & 4) != 0) {
          FUN_0044f4a0(this);
        }
      }
    }
  }
  else {
    if ((*(int *)((int)this + 4) == 0) && (*(int *)this == 0)) {
      bVar4 = false;
    }
    else {
      bVar4 = true;
    }
    if (((!bVar4) || (*(int *)((int)this + 0x14) != param_1[6])) ||
       (*(int *)((int)this + 0x18) != param_1[5])) {
      FUN_0044cfb0(this,param_1[6],param_1[5],8,0,-1);
    }
    if ((*(int *)this != 0) || (bVar4 = FUN_0044e840(this), bVar4)) {
      bVar4 = true;
    }
    else {
      bVar4 = false;
    }
    if (bVar4) {
      if ((*param_1 != 0) || (bVar4 = FUN_0044e840(param_1), bVar4)) {
        bVar4 = true;
      }
      else {
        bVar4 = false;
      }
      if (bVar4) {
        if ((param_2 & 4) == 0) {
          local_10 = *(undefined1 **)this;
        }
        else {
          local_10 = (undefined1 *)
                     (*(int *)((int)this + 0x1c) * (*(int *)((int)this + 0x18) + -1) + *(int *)this)
          ;
        }
        iVar10 = *(int *)((int)this + 0x18);
        iVar6 = *(int *)((int)this + 0x14);
        if ((param_2 & 4) == 0) {
          iVar7 = *(int *)((int)this + 0x1c) - iVar6;
        }
        else {
          iVar7 = -(*(int *)((int)this + 0x1c) + iVar6);
        }
        iVar8 = iVar6;
        if ((param_2 & 2) == 0) {
          puVar9 = (undefined1 *)(*param_1 + -1 + param_1[5]);
          local_8 = param_1[7];
          param_1 = (int *)(-1 - local_8 * param_1[6]);
        }
        else {
          iVar1 = param_1[7];
          puVar9 = (undefined1 *)((param_1[6] + -1) * iVar1 + *param_1);
          local_8 = -iVar1;
          param_1 = (int *)(iVar1 * param_1[6] + 1);
        }
        do {
          do {
            *local_10 = *puVar9;
            puVar9 = puVar9 + local_8;
            local_10 = local_10 + 1;
            iVar8 = iVar8 + -1;
          } while (iVar8 != 0);
          puVar9 = puVar9 + (int)param_1;
          local_10 = local_10 + iVar7;
          iVar10 = iVar10 + -1;
          iVar8 = iVar6;
        } while (iVar10 != 0);
        return 1;
      }
    }
  }
  return uVar5;
}


