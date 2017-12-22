using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Obi;

public class AudioScript : MonoBehaviour {
	private GameObject emitter;
	private ObiEmitter emi;
	private GameObject audio;
	private bool isAudio = false;
	public float audioStartParticles;

	// Use this for initialization
	void Start () {
		audio = GameObject.Find ("Audio");
		emitter = GameObject.Find ("Emitter");
		emi = emitter.GetComponent<ObiEmitter> ();
	}
	
	// Update is called once per frame
	void Update () {
		if (emi.ActiveParticles > audioStartParticles && isAudio == false) {
			audio.GetComponent<AudioSource>().Play();
			isAudio = true;
		}
	}
}
