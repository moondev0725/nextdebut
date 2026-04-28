package com.java.dto;

import com.java.game.entity.Gender;
import com.java.game.entity.Grade;
import java.time.LocalDate;

public class TraineeUpdateRequest {

	private String name;
	private Gender gender;
	private Integer age;
	private LocalDate birthday;
	private Integer height;
	private Grade grade;
	private String hobby;
	private String instagram;
	private String unlockCondition;
	private Integer unlockScore;

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public Gender getGender() {
		return gender;
	}

	public void setGender(Gender gender) {
		this.gender = gender;
	}

	public Integer getAge() {
		return age;
	}

	public void setAge(Integer age) {
		this.age = age;
	}

	public LocalDate getBirthday() {
		return birthday;
	}

	public void setBirthday(LocalDate birthday) {
		this.birthday = birthday;
	}

	public Integer getHeight() {
		return height;
	}

	public void setHeight(Integer height) {
		this.height = height;
	}

	public Grade getGrade() {
		return grade;
	}

	public void setGrade(Grade grade) {
		this.grade = grade;
	}

	public String getHobby() {
		return hobby;
	}

	public void setHobby(String hobby) {
		this.hobby = hobby;
	}

	public String getInstagram() {
		return instagram;
	}

	public void setInstagram(String instagram) {
		this.instagram = instagram;
	}

	public String getUnlockCondition() {
		return unlockCondition;
	}

	public void setUnlockCondition(String unlockCondition) {
		this.unlockCondition = unlockCondition;
	}

	public Integer getUnlockScore() {
		return unlockScore;
	}

	public void setUnlockScore(Integer unlockScore) {
		this.unlockScore = unlockScore;
	}
}
