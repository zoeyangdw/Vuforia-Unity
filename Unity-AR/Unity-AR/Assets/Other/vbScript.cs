using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Vuforia;
using Obi;

public class vbScript : MonoBehaviour, IVirtualButtonEventHandler {

	private GameObject vbButtonObject;
	private GameObject startButton;
	private GameObject stopButton;
	private GameObject emitter;
	private ObiEmitter emi;
	private moveOnPath move;
	private float speed;

	// Use this for initialization
	void Start () {
		vbButtonObject = GameObject.Find ("actionButton");
		vbButtonObject.GetComponent<VirtualButtonBehaviour> ().RegisterEventHandler (this);
		emitter = GameObject.Find ("Emitter");
		startButton = GameObject.Find ("startButton");
		stopButton = GameObject.Find ("stopButton");
		//audio = GameObject.Find ("Audio");
		move = GameObject.Find ("PaperAirplane").GetComponent<moveOnPath> ();

		emi = emitter.GetComponent<ObiEmitter> ();
		speed = emi.speed;
		emi.speed = 0;
		//stopButton.GetComponent<Renderer>().enabled = false;
		stopButton.active = false;
		startButton.active = true;
	}
	
	// Update is called once per frame
	void Update () {
		
	}

	public void OnButtonPressed(VirtualButtonAbstractBehaviour vb) {
//		emitter = GameObject.Find ("Emitter");
//		emi = emitter.GetComponent<ObiEmitter> ();
		if (emi.speed != 0) {
			emi.speed = 0;
			startButton.active = true;
			stopButton.active = false;
		} else {
			emi.speed = speed;
			startButton.active = false;
			stopButton.active = true;
		}
	}

	public void OnButtonReleased(VirtualButtonAbstractBehaviour vb) {

	}

}
