using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MultiObjects : MonoBehaviour {
	public float width;
	public float height;
	public GameObject butterfly;

	// Use this for initialization
	void Start () {
		SetBasicValues ();
		Debug.Log (width);
		Debug.Log (height);
	}


	// Update is called once per frame
	void Update () {

		if (Input.GetMouseButtonUp (0)) {
			Debug.Log ("mouse");
				Ray ray = Camera.main.ScreenPointToRay (Input.mousePosition);
				RaycastHit hit;
				if (Physics.Raycast (ray, out hit)) {
					Debug.Log (hit.point);
				GameObject point= GameObject.Instantiate (butterfly, hit.point, transform.rotation)as GameObject;
			}
		}


		int i = 0;  
		if (Input.touchCount > 0 && Input.GetTouch(0).phase == TouchPhase.Moved) {
			Debug.Log ("input");
		}
//		while (i < Input.touchCount) {  
//			if (Input.GetTouch(i).phase == TouchPhase.Moved) {
//				Debug.Log ("touch");
//				Ray ray = Camera.main.ScreenPointToRay(Input.GetTouch(i).position);  
//				if (Physics.Raycast(ray))  
//					Instantiate(butterfly, transform.position, transform.rotation);  
//			}  
//			++i;  
//		}    
	}


	void SetBasicValues(){

		float leftBorder;
		float rightBorder;
		float topBorder;
		float downBorder;
		//the up right corner
		Vector3 cornerPos=Camera.main.ViewportToWorldPoint(new Vector3(1f,1f,Mathf.Abs(Camera.main.transform.position.z)));

		leftBorder=Camera.main.transform.position.x-(cornerPos.x-Camera.main.transform.position.x);
		rightBorder=cornerPos.x;
		topBorder=cornerPos.y;
		downBorder=Camera.main.transform.position.y-(cornerPos.y-Camera.main.transform.position.y);

		width=rightBorder-leftBorder;
		height=topBorder-downBorder;
	}
}
