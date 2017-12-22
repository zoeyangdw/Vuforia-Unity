using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Obi;

public class moveOnPath : MonoBehaviour {

	public editPath PathToFollow;

	public int CurrentWayPointID = 0;
	public float speed;
	private float reachDistance = 0.2f;
	public float rotationSpeed = 5.0f;
	public string pathName;
	public bool isPlane = false;

	private GameObject emitter;
	private ObiEmitter emi;
	public float moveStartParticles;

	Vector3 last_position;
	Vector3 current_position;

	// Use this for initialization
	void Start () {
		PathToFollow = GameObject.Find (pathName).GetComponent<editPath>();
		transform.eulerAngles = new Vector3 (0, 180, 0);
		last_position = transform.position;
	}
	
	// Update is called once per frame
	void Update () {
		if (emi.ActiveParticles > moveStartParticles) {
			isPlane = true;
		}
		//Debug.Log (start);
		if (CurrentWayPointID < PathToFollow.path_objs.Count && isPlane) {
			float distance = Vector3.Distance (PathToFollow.path_objs [CurrentWayPointID].position, transform.position);
			transform.position = Vector3.MoveTowards (transform.position, PathToFollow.path_objs [CurrentWayPointID].position, Time.deltaTime * speed);
			if (distance <= reachDistance) {
				CurrentWayPointID++;
			}
			var rotation = Quaternion.LookRotation (PathToFollow.path_objs [CurrentWayPointID].position - transform.position);// + new Vector3(0,180,0));
			transform.rotation = Quaternion.Slerp (transform.rotation, rotation, Time.deltaTime * rotationSpeed);
			//Debug.Log (PathToFollow.path_objs.Count);
		}

	}
}
