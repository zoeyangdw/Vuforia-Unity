#pragma strict

var startTime = 5.0f;
//@RequireComponent(AudioSource)
function Start () {
	Debug.Log("audio");
	InvokeRepeating("PlayAudio", startTime, 50.0f);
	//var audio:AudioSource = GetComponent.<AudioSource>();
}

function Update () {
	
}

//@RequireComponent(AudioSource)
function PlayAudio() {
	GetComponent.<AudioSource>().Play();
	//Debug.Log('play');
}


