﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FernTransferLifeForm :TransferLifeForm{

  public FernVerts fern;

  public override void BindAttributes(){

    transfer.BindForm("_FernBuffer" , fern);
    transfer.BindAttribute("_VertsPerVert" , "vertsPerVert" , fern);
    
  }



}
